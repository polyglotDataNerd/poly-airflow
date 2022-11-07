import os
import logging
import re
import zipfile

import boto3
from airflow.providers.ssh.hooks.ssh import SSHHook
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.hooks.base import BaseHook
from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults
from botocore.client import BaseClient
from stat import S_ISREG

from paramiko import SFTPClient, SSHException

log = logging.getLogger(__name__)

DEFAULT_LOCAL_WORK_DIR = './run'


def get_s3_client(conn_id) -> BaseClient:
    aws_credentials = S3Hook(aws_conn_id=conn_id).get_credentials()
    log.info("Using connection: {}".format(conn_id))
    s3_client = boto3.client(
        's3',
        aws_access_key_id=aws_credentials.access_key,
        aws_secret_access_key=aws_credentials.secret_key
    )
    return s3_client


class SFTPGetHook(BaseHook):

    def __init__(self, conn_id):
        super().__init__(None)
        self.conn_id = conn_id
        self.sftp_client = None

    def cd(self, folder):
        log.info("Change dir to {}".format(folder))
        self._get_connection().chdir(folder)

    def _list_using_func(self, filter_func) -> list:
        log.info("Listing files using function")
        directory_structure = self._get_connection().listdir_attr()
        files = []
        for attr in directory_structure:
            if filter_func(attr.filename):
                files.append(attr.filename)
        return files

    def _list_using_regex(self, file_pattern) -> list:
        log.info("Listing files using regex {}".format(file_pattern))
        directory_structure = self._get_connection().listdir_attr()
        files = []
        for attr in directory_structure:
            if re.match(file_pattern, attr.filename):
                files.append(attr.filename)
        return files

    def download_files(self, dest_local_folder: str, regex: str = None, filter_func=None, mode="binary"):
        if (regex is not None) and (filter_func is not None):
            raise Exception("Exactly one of regex or filter_func must be specified")
        if regex is not None:
            log.info(f"Regex used: {regex}\n")
            file_list = self._list_using_regex(regex)
        else:
            file_list = self._list_using_func(filter_func)
        if file_list is None:
            raise Exception("Exactly one of regex or filter_func must be specified")

        self._download_files_to_local_folder(file_list, dest_local_folder, mode)

    def _download_files_to_local_folder(self,
                                        file_list,
                                        dest_local_folder,
                                        mode,
                                        create_dest_local_folder=True):
        if create_dest_local_folder:
            os.makedirs(dest_local_folder, exist_ok=True)

        log.info("Downloading files from (S)FTP server, connection {}".format(self.conn_id))
        for remote_file_name in file_list:
            if self.isfile(remote_file_name):
                local_file_name = os.path.join(dest_local_folder, remote_file_name)
                log.info("Downloading remote file {} to {}".format(remote_file_name, local_file_name))
                if mode == "text":
                    log.info("Using text mode")
                    self._get_text_file(remote_file_name, local_file_name)
                else:
                    log.info("Using binary mode")
                    self._get_connection().get(remote_file_name, local_file_name)

    def _get_connection(self) -> SFTPClient:
        if self.sftp_client is None:
            log.info("Connecting to SFTP server, connection {}".format(self.conn_id))
            ssh_hook = SSHHook(ssh_conn_id=self.conn_id)
            client = ssh_hook.get_conn()
            tr = client.get_transport()
            # tr.default_max_packet_size = 100000000
            # tr.default_window_size = 100000000
            self.sftp_client = client.open_sftp()
        return self.sftp_client

    def isfile(self, remotepath):
        try:
            result = S_ISREG(self._get_connection().stat(remotepath).st_mode)
        except IOError:  # no such file
            result = False
        return result

    def _get_text_file(self, sftp_path, dst_path):
        log.info("Getting file {}".format(sftp_path))
        try:
            sftp = self._get_connection()
            with sftp.open(sftp_path, 'r') as remote:
                with open(dst_path, 'w') as local:
                    for line in remote:
                        local.write(line)
        except SSHException:
            log.error("SSH error")
        log.info("File downloaded {}".format(sftp_path))

    def __del__(self):
        if self.sftp_client is not None:
            try:
                log.info("Closing SFTP connection {}".format(self.conn_id))
                self.sftp_client.close()
                log.info("SFTP connection {} successfully closed".format(self.conn_id))
            except:
                log.info("Failed to close SFTP connection {}".format(self.conn_id))
                pass


class SFTPToS3Operator(BaseOperator):
    template_fields = ('file_filter_func', 'file_regex',)

    @apply_defaults
    def __init__(self,
                 sftp_conn_id,
                 s3_conn_id,
                 sftp_folder,
                 s3_bucket,
                 s3_path,
                 file_regex=None,
                 file_filter_func=None,
                 unzip=False,
                 mode="binary",
                 *args,
                 **kwargs):
        super(SFTPToS3Operator, self).__init__(provide_context=True, *args, **kwargs)
        self.sftp_conn_id = sftp_conn_id
        self.s3_conn_id = s3_conn_id
        self.sftp_folder = sftp_folder
        self.s3_bucket = s3_bucket
        self.s3_path = s3_path
        self.file_regex = file_regex
        self.file_filter_func = file_filter_func
        self.unzip = unzip
        self.mode = mode

    def execute(self, context):
        sftp_hook: SFTPGetHook = SFTPGetHook(conn_id=self.sftp_conn_id)
        s3_conn: BaseClient = get_s3_client(conn_id=self.s3_conn_id)

        if self.sftp_folder is not None:
            sftp_hook.cd(self.sftp_folder)

        task_dir = DEFAULT_LOCAL_WORK_DIR + '/' + self.task_id
        sftp_hook.download_files(task_dir, self.file_regex, self.file_filter_func, self.mode)
        if self.unzip:
            for local_file_name in os.listdir(task_dir):
                if '.zip' in local_file_name:
                    full_file_path = task_dir + '/' + local_file_name
                    log.info('Unzipping file {}'.format(local_file_name))
                    with zipfile.ZipFile(full_file_path, "r") as zip_ref:
                        zip_ref.extractall(task_dir)
                        os.remove(full_file_path)

        for local_file_name in os.listdir(task_dir):
            s3_key = (self.s3_path + '/' + local_file_name).replace('//', '/')
            log.info('Loading file {} to bucket {}, key {}'.format(local_file_name, self.s3_bucket, self.s3_path))
            s3_conn.upload_file(
                task_dir + '/' + local_file_name,
                self.s3_bucket,
                s3_key
            )
