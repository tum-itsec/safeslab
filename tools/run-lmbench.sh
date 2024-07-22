#!/bin/bash

cd lmbench/bin/x86_64-linux-gnu/

REPS=20
export REPS

cp hello /tmp/
for i in `seq 1 ${REPS}`; do ./lat_proc shell; done;
for i in `seq 1 ${REPS}`; do ./lat_proc exec; done;
for i in `seq 1 ${REPS}`; do ./lat_proc fork; done;
for i in `seq 1 ${REPS}`; do ./lat_sig prot ./lat_sig; done;
./lat_udp -s
for i in `seq 1 ${REPS}`; do ./lat_udp localhost; done;
./lat_tcp -s
for i in `seq 1 ${REPS}`; do ./lat_tcp localhost; done;
for i in `seq 1 ${REPS}`; do ./lat_unix; done;
for i in `seq 1 ${REPS}`; do ./lat_pipe; done;
for i in `seq 1 ${REPS}`; do ./lat_sig catch; done;
for i in `seq 1 ${REPS}`; do ./lat_sig install; done;
for i in `seq 1 ${REPS}`; do ./lat_select -n 10 tcp; done;
for i in `seq 1 ${REPS}`; do ./lat_select -n 500 tcp; done;
for i in `seq 1 ${REPS}`; do ./lat_select -n 10 file; done;
for i in `seq 1 ${REPS}`; do ./lat_select -n 500 file; done;
for i in `seq 1 ${REPS}`; do ./lat_syscall open ./lat_syscall; done;
for i in `seq 1 ${REPS}`; do ./lat_syscall fstat /tmp/hello; done;
for i in `seq 1 ${REPS}`; do ./lat_syscall stat ./lat_syscall; done;
for i in `seq 1 ${REPS}`; do ./lat_syscall write /tmp/hello; done;
for i in `seq 1 ${REPS}`; do ./lat_syscall read /tmp/hello; done;
for i in `seq 1 ${REPS}`; do ./lat_syscall null; done;
