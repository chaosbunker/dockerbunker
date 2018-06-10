#!/usr/bin/env python

# initially stolen from: https://github.com/jirutka/haste-client
# adapted to be only for python 3
# added get snippet feature and crypt snippet feature
# change the server url in CONFIG if needed

"""
haste - a CLI client for Haste server.

Usage:
    haste send [-r] [--password=<pwd>] [FILE]
    haste get [--password=<pwd>] KEY

Options:
    -r --raw            Return a URL to the raw paste data.
    --password=<pwd>    Encrypt/decrypt message using <pwd> as password.
    -h --help           Show this message.
    -v --version        Show version.

If FILE is not specified, haste will read from standard input.
"""

import os
from base64 import b64decode, b64encode
import json
import sys
import docopt
import requests
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.backends import default_backend
_BACKEND = default_backend()

__version__ = '2.0.1'

CONFIG = {
    'server_url': "https://hastebin.com",
    'timeout': 3
}

def main(**kwargs):
    """ main function: do actions following args """

    if kwargs['KEY'] and kwargs['get']:
        data = get_snippet(kwargs['KEY'], CONFIG['server_url'], CONFIG['timeout'])
        if kwargs['--password']:
            data = decrypt(kwargs['--password'], json.loads(data)).decode("utf-8")
        print(data)
    elif kwargs['send']:
        data = read_file(kwargs['FILE']) if kwargs['FILE'] else read_stdin()
        if kwargs['--password']:
            data = json.dumps(encrypt(kwargs['--password'], data))
        url = create_snippet(data, CONFIG['server_url'], CONFIG['timeout'], kwargs['--raw'])
        print(url)
    else:
        print(docopt.docopt(__doc__))

def get_snippet(dockey, baseurl, timeout):
    """ get a snippet from the server """
    try:
        url = baseurl + "/raw/" + dockey
        response = requests.get(url, timeout=float(timeout))
    except requests.exceptions.Timeout:
        exit("Error: connection timed out")

    return response.text

def create_snippet(data, baseurl, timeout, raw):
    """
    Creates snippet with the given data on the haste server specified by the
    baseurl and returns URL of the created snippet.
    """
    try:
        url = baseurl + "/documents"
        response = requests.post(url, data.encode('utf-8'), timeout=float(timeout))
    except requests.exceptions.Timeout:
        exit("Error: connection timed out")

    dockey = json.loads(response.text)['key']
    return baseurl + ("/raw/" if raw else "/") + dockey

def read_stdin():
    """ joins lines of stdin into a single string """
    return "".join(sys.stdin.readlines()).strip()

def read_file(path):
    """ reads lines of a file and joins them into a single string """
    try:
        with open(path, 'r') as text_file:
            return "".join(text_file.readlines()).strip()
    except IOError:
        exit("Error: file '%s' is not readable!" % path)

def decrypt(pwd, data):
    """ Decrypt using password and input json """

    ct = b64decode(data['ct'])
    salt = b64decode(data['salt'])
    tag_start = len(ct) - data['ts'] // 8
    tag = ct[tag_start:]
    ciphertext = ct[:tag_start]

    mode_class = getattr(modes, data['mode'].upper())
    algo_class = getattr(algorithms, data['cipher'].upper())

    kdf = _kdf(data['ks'], iters=data['iter'], salt=salt)[0]
    key = kdf.derive(bytes(pwd, "utf-8"))
    cipher = Cipher(
        algo_class(key),
        mode_class(
            b64decode(data['iv']),
            tag,
            min_tag_length=data['ts'] // 8
        ),
        backend=_BACKEND
    )

    dec = cipher.decryptor()
    return dec.update(ciphertext) + dec.finalize()

def _kdf(keysize=128, iters=256000, salt=None):
    """ Returns a key derivation function: used to create a strong key based on the input """
    kdf_salt = salt or os.urandom(8)
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=keysize // 8,
        salt=kdf_salt,
        iterations=iters,
        backend=_BACKEND
    )

    return kdf, kdf_salt

def encrypt(pwd, plaintext, mode='gcm', keysize=128, tagsize=128, iters=256000):
    """ Encrypt plain text using password. Outputs json """

    ts = tagsize // 8

    mode_class = getattr(modes, mode.upper())
    algo_class = getattr(algorithms, 'AES')

    iv = os.urandom(16)
    kdf, salt = _kdf(keysize, iters)
    bpwd = str.encode(pwd)
    key = kdf.derive(bpwd)
    cipher = Cipher(
        algo_class(key),
        mode_class(iv, min_tag_length=ts),
        backend=_BACKEND
    )

    enc = cipher.encryptor()
    btext = str.encode(plaintext)
    ciphertext = enc.update(btext) + enc.finalize()
    output = {
        "v": 1,
        "iv": b64encode(iv).decode("utf-8"),
        "salt": b64encode(salt).decode("utf-8"),
        "ct": b64encode(ciphertext + enc.tag[:ts]).decode("utf-8"),
        "iter": iters,
        "ks": keysize,
        "ts": tagsize,
        "mode": mode,
        "cipher": 'aes',
        "adata": ""
    }
    return output

DOC = docopt.docopt(__doc__, version='haste ' + __version__)
if __name__ == "__main__":
    main(**DOC)
