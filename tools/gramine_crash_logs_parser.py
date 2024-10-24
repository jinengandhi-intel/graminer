import os
import subprocess
import re
import sys
import pathlib
import psutil
import time


def get_existing_crashes(crash_dir):
    known_crashes = {}
    subfolders = [ f.path for f in os.scandir(crash_dir) if f.is_dir() ]
    for subf in subfolders:
        with open(os.path.join(crash_dir, subf, "description"), mode="r") as fd:
            key = fd.read()
            known_crashes[key] = subf
    return known_crashes

def get_existing_crash_hash(crash_dir):
    known_hash = []
    subfolders = [ f.path for f in os.scandir(crash_dir) if f.is_dir() ]
    for subf in subfolders:
        for path in pathlib.Path(os.path.join(crash_dir, subf)).glob("report*"):
            with open(str(path)) as f:
                known_hash.append(f.read().strip())
    return known_hash

def get_crash_list(crash_dir):
    crash_list = [os.path.basename(path).split(".c")[0].replace("crash-", '') for path in pathlib.Path(crash_dir).glob("*.c")]
    return crash_list

def match_list(desc, known_crashes):
    res = list(filter(lambda x: desc in x, known_crashes.keys()))
    if res:
        return res[0]
    return None

def check_for_existing_crashes(desc, c_hash, known_crashes, known_hash):
    out = None
    m_res = match_list(desc, known_crashes)
    if m_res and c_hash in known_hash:
        return "Hash Exists"
    elif m_res and c_hash not in known_hash:
        out = known_crashes[m_res]
    return out


def get_log_file_length(res_dir):
    count = 0
    files_count = [int(str(path).split("log")[1]) for path in pathlib.Path(os.path.join(res_dir)).glob("log*")]
    if files_count:
        count = max(files_count)
    return count

def copy_files(c_hash, s_dir, count, desc=None):
    if (count == 0):
        os.mkdir(s_dir)
        with open(os.path.join(workdir, s_dir, "description"), mode="w") as fd:
                fd.write(desc)
    subprocess.getoutput(f"cp -rf crash-{c_hash}.c {s_dir}/crash-{c_hash}.c")
    subprocess.getoutput(f"cp -rf crash-{c_hash}.log {s_dir}/log{count}")
    with open(os.path.join(workdir, s_dir, f"report{count}"), mode="w") as fd:
        fd.write(c_hash)

def check_and_copy_crashes(c_hash, desc, known_crashes, known_hashes):
    res = check_for_existing_crashes(desc, c_hash, known_crashes, known_hashes)
    if res == "Hash Exists":
        pass
    elif res:
        count = get_log_file_length(res) + 1
        copy_files(c_hash, res, count)
    else:
        if known_crashes.values():
            try:
                issue_list = [int(os.path.basename(k_v).split("_")[1]) for k_c, k_v in known_crashes.items() if (k_c != "lost connection to test machine\n") and ("manifest syntax is deprecated" not in k_c)]
            except Exception as e:
                print("Exception occured: ", desc)
                issue_list = []
            if not issue_list:
                issue_count = "1"
            else:
                issue_count = max(issue_list) + 1
        else:
            issue_count = "1"
        file_dir = f"Issue_{issue_count}_{c_hash}"
        desc = f"Issue_{issue_count}: {desc.strip()}"
        copy_files(c_hash, file_dir, 0, desc)
        known_hashes.append(c_hash)
        known_crashes[desc] = file_dir


def create_syzcaller_format(c_hash, known_crashes, known_hashes):
    log_file = f"crash-{c_hash}.log"
    res = []
    try:
        crash_fd = open(log_file, mode="r", encoding='latin-1')
        crash_contents = crash_fd.read()
        res = re.findall("assert(.*)", crash_contents)
        res += re.findall("(Internal memory fault.*)", crash_contents)

        if not res:
            res += re.findall("error: (.*)", crash_contents)
        if "Child process (vmid: 0x2) got disconnected" in res:
            while "Child process (vmid: 0x2) got disconnected" in res: res.remove("Child process (vmid: 0x2) got disconnected")
        if "Unsupported combination of flags passed to waitid/wait4" in res:
            while "Unsupported combination of flags passed to waitid/wait4" in res: res.remove("Unsupported combination of flags passed to waitid/wait4")
    except Exception as e:
        pass

    if res:
        for index in range(len(res)):
            desc = res[index]
            check_and_copy_crashes(c_hash, desc, known_crashes, known_hashes)
    else:
        desc = f"Crash Analysis needed for {c_hash}"
        check_and_copy_crashes(c_hash, desc, known_crashes, known_hashes)

def crash_analysis(workdir, hashes_list):
    os.chdir(workdir)
    print("No of crash reported are ", len(hashes_list))
    known_hashes = get_existing_crash_hash(workdir)
    known_crashes = get_existing_crashes(workdir)
    for c_hash in hashes_list:
        create_syzcaller_format(c_hash, known_crashes, known_hashes)


def check_syz_manager_process():
    proc_run = "syz-manager" in (proc.name() for proc in psutil.process_iter())
    return proc_run

if __name__ == "__main__":
    workdir = sys.argv[1]
    curr_dir = os.getcwd()
    test_run = True
    wait_count = 0
    hashes_list = get_crash_list(workdir)
    crash_analysis(workdir, hashes_list)