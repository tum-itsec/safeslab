<div align="center">

# Safeslab

#### Mitigating Use-After-Free Vulnerabilities via Memory Protection Keys

</div>

Restricting dangling pointers from accessing freed memory is a promising technique for mitigating use-after-free
vulnerabilities in memory-unsafe programming languages. However, existing solutions suffer from high performance
overheads, as they rely on conventional page table manipulation to make dangling pointers inaccessible. In this paper,
we present Safeslab: a heap-hardening extension that aims to mitigate use-after-free vulnerabilities via a novel and
efficient address aliasing approach. Safeslab assigns multiple virtual aliases to each memory page in the system, and
manages their access rights via the recently introduced Memory Protection Keys hardware extension, which is designed to
provide a fast alternative to page tables for memory management. This allows Safeslab to drastically reduce the number
of page table modifications, while blocking dangling pointers efficiently. We integrated Safeslab into the Linux
kernel, replacing its default heap allocator (SLUB). The results of our experimental evaluation with real-world
benchmarks show that Safeslab incurs a negligible runtime overhead of up to 4% and moderate memory waste.

Further information about the design and implementation of Safeslab can be found in our [paper](./misc/safeslab.pdf)
presented at [CCS 2024](https://www.sigsac.org/ccs/CCS2024/program.html).

```
@article{momeu2024safeslab,
  title={Safeslab: Mitigating Use-After-Free Vulnerabilities via Memory Protection Keys},
  author={Momeu, Marius and Schn{\"u}ckel, Simon and Angnis, Kai and Polychronakis, Michalis and Kemerlis, Vasileios P},
  booktitle={Proceedings of the ACM SIGSAC Conference on Computer and Communications Security (CCS)},
  pages={XXX--YYY},
  year={2024}
}
```

## Table of Contents

 - [Directory Structure](#directory-structure)
 - [Supported Environment](#supported-environment)
 - [Major Claims & Experiments](#major-claims-&-experiments)
 - [Setup](#setup)
 - [Build](#build)
 - [Functionality Test](#functionality-test)
 - [Evaluate](#evaluate)
 - [Clean](#clean)
 - [License](#license)

## Directory Structure

 - [`configs`](./configs): configs for building the various Linux kernels we used in our experiments
 - [`linux-6.2.0`](./linux-6.2.0): the baseline Linux kernel we used for implementing Safeslab
 - [`misc`](./misc): miscellaneous items
 - [`patches`](./patches): Safeslab patches for Linux 6.2
 - [`tools`](./tools): Bash scripts for assisting in building, deploying, and evaluating Safeslab

## Supported Environment

This prototype of Safeslab assumes an x86_64 machine running Debian (Bullseye or higher) Linux with at least 64GB of
RAM, 16 available CPU cores, and approximately 100GB of storage space. While we use QEMU/KVM to recreate the environment
used in the paper, benchmark numbers were actually collected on bare-metal. Specifically, we used a machine with an
Intel Core I9 12th Gen (24-CPU) processor and 64GB of DDR4 memory running Debian v11 (Bullseye) Linux with kernel
v6.2.0. Most notably, the CPU must support the PKU variant of the MPK feature of recent Intel processors, available on
11th Gen or higher on client CPUs, and Skylake or higher on server CPUs. For testing whether the machine supports PKU,
running the following command should not return an empty output:

```bash
lscpu | grep -i pku
```

## Major Claims & Experiments

#### Performance

 - **(C1):** Saefslab exhibits either negligible (<= 5%) or no slowodown at all in more than 3/4 of the LMbench tests,
   and moderate slowdown in the rest of the LMbench tests, with an overall geomean of ~1.04%. This claim is proven by
   experiment E1, which is described in our paper in Section 6.1.1.
 - **(E1):** Benchmark and compare the performance of several tests from the LMBench suite under a vanilla (baseline)
   Linux kernel, and a Linux kernel hardened with Safeslab. This experiment is described in our paper in Section 6.1.1.

 - **(C2):** In almost all tests from the Phoronix Test Suite, Safeslab exhibits either negligible (<= 3%) or no
   slowdown at all, except for Hackbench on which it incurs moderate slowdown, with an overall geomean of ~1.03%. This
   claim is proven by experiment E2, which is described in our paper in Section 6.1.2.
 - **(E2):** Benchmark and compare the performance of several tests from the Phoronix Test Suite under a vanilla
   (baseline) Linux kernel, and a Linux kernel hardened with Safeslab. This experiment is described in our paper in
   Section 6.1.2.

#### Memory 
 
 - **(C3):** Safeslab exhibits moderate memory consumption overhead during the boot stage of the system as well as
   during several tests from the Phoronix Test Suite. This claim is proven by experiment E3, which is described in our
   paper in Section 6.2.
 - **(E3):** Benchmark and compare the memory consumption of the boot stage and several tests from the Phoronix Test
   Suite under a vanilla (baseline) Linux kernel, and a Linux kernel hardened with Safeslab. This experiment is
   described in our paper in Section 6.2.

## Setup

To reproduce the main claims of the paper, we have recreated the bare-metal benchmarking environment we used in the
paper with virtualization, specifically, [QEMU](https://www.qemu.org/)/[KVM](https://www.linux-kvm.org/page/Main_Page).
At a high-level, we create a single root filesystem that contains all of the benchmarks and scripts required to evaluate
Safeslab. Then, we build two custom Linux kernels: an unmodified one that uses the vanilla SLUB allocator as a heap
allocator, and a hardened one that uses Safeslab instead of SLUB to mitigate Use-After-Free (UAF) vulnerabilities.
Finally, we run QEMU/KVM using these components to get an evaluation environment that we can use to reproduce Safeslab's
results. 

### Packages

Various packages are required to use QEMU as well as build the Linux kernel and the root filesystem. On Debian Bullseye, the required packages can be installed as follows:

```shell
sudo apt-get install build-essential libncurses-dev bison flex bc libssl-dev libelf-dev zstd debootstrap qemu-utils qemu-system-x86 debootstrap wget gdb openssh-client git
```

On other distributions, the required package names may vary.

### Virtualization

As mentioned above, we use QEMU/KVM to recreate the major claims from the paper in a portable manner. In order to run the virtual machines:

 - Ensure that the user is in the `kvm` group
 - Ensure that `/dev/kvm` exists

<details>
<summary>Troubleshooting</summary>

To troubleshoot issues with KVM, the tool `kvm-ok` can be useful. Install it with:

```shell
sudo apt-get install cpu-checker
```

If things are successful, running `kvm-ok` should output:

```
INFO: /dev/kvm exists
KVM acceleration can be used
```
</details>

## Build

### Use Pre-built Environment

For convenience, we provide a pre-built environment (e.g., kernels, rootfs, etc.). To use it, download `prebuilt.tar.gz` from our
prototype's [Zenodo record](https://zenodo.org/records/12780080), and decompress it:

```shell
tar -xzf prebuilt.tar.gz
```

The result should be a `build` directory in the root of this repository containing several files whose purpose is described below.

### Build from Scratch

We also provide scripts to build the entire environment from scratch. From the root of the repository, run:

```shell
./tools/safeslab build all
```

This will:

 1. Create a root filesystem at `./build/rootfs/rootfs.img` using [Debootstrap](https://wiki.debian.org/Debootstrap).
 2. Build four Linux kernels based on v6.2.0:
    - `vanilla`: unmodified 
    - `vanilla-membench`: vanilla instrumented for analyzing SLUB's memory consumption
    - `safeslab`: hardened with Safeslab
    - `safeslab-membench`: hardened with Safeslab and instrumented for analyzing Safeslab's memory consumption 
 3. Download and install the benchmarks within the root filesystem:
    - LMBench 
    - Phoronix Test Suite
    - Custom Memory Overhead Benchmark

All of the above should happen automatically without requiring input from the user. Depending on the machine used to
build things, this step can take anywhere from one to several hours. Notably, `./tools/safeslab build` can also perform
the tasks above individually. For more information regarding this, run:

```shell
./tools/safeslab build help
```

<details>
<summary>Additional Details</summary>

Our build script first applies the patch that contains our modifications, located at `./patches/6.2.0-safeslab.patch`,
on top of the unmodified Linux kernel v6.2, located at `./linux-6.2.0`. This will create a patched kernel codebase
located at `./build/src/`. The script then uses the configs located in `./configs` to build the various Linux kernels
used in our experiments; they are the same configs we used to evaluate Safeslab bare-metal, and, as such, they enable
quite a large number of loadable kernel modules -- this increases build time and the size of the generated object files.
After building the kernels, the script also generates initrd images required to boot them based on the template provided
in `./tools/initrd`. The resulting object files, kernel images and initrd are located at `./build/obj/`.

Note that we also provide a patch for vanilla Linux, which merely adds the required instrumentation for evaluating
SLUB's memory consumption, and is only enabled when building `vanilla-membench`. Also, note that we build separate
kernels for evaluating memory consumption (`vanilla-membench` and `safeslab-membench`) because they employ additional
instrumentation that is unneccesary for the correct functioning of Safeslab and SLUB, and would otherwise only add
unwanted performance overhead. 
</details>

## Functionality Test

Run the following command to test that Safeslab boots and initializes properly:

```shell
./tools/safeslab run sanity
```

The expected output should be similar to:

```
[    0.056832] safeslab_clone_kernel_physical_mapping cloning paddr [100000 --> 200000)
[    0.056902] safeslab_clone_kernel_physical_mapping cloning paddr [200000 --> 1000000)
[    0.061228] safeslab_clone_kernel_physical_mapping cloning paddr [320d000 --> 8503a000)
[    0.061951] safeslab_clone_kernel_physical_mapping cloning paddr [100000000 --> 81c200000)
[    0.066791] safeslab_clone_kernel_physical_mapping cloning paddr [83ffad000 --> 83ffae000)
[    0.068628] Safeslab initialized!
[    0.143234] safeslab_clone_kernel_physical_mapping cloning paddr [ffffffff82d5f000 --> ffffffff82d67000)
[    4.075756] safeslab_clone_kernel_physical_mapping cloning paddr [ffff88808903a000 --> ffff888089200000)
[    4.075807] safeslab_clone_kernel_physical_mapping cloning paddr [ffff888089200000 --> ffff8880bfe00000)
[    4.076450] safeslab_clone_kernel_physical_mapping cloning paddr [ffff8880bfe00000 --> ffff8880bffe0000)
[    4.156085] safeslab_clone_kernel_physical_mapping cloning paddr [ffffffff83003000 --> ffffffff83200000)
[    4.158145] safeslab_clone_kernel_physical_mapping cloning paddr [ffffffff829e8000 --> ffffffff82a00000)
[    4.158164] safeslab_clone_kernel_physical_mapping cloning paddr [ffffffff82a00000 --> ffffffff82c00000)
[    4.158948] safeslab_clone_kernel_physical_mapping cloning paddr [ffffffff82c00000 --> ffffffff82d5f000)
[    4.181287] safeslab_clone_kernel_physical_mapping cloning paddr [ffffffff8233c000 --> ffffffff82400000)
```

Additional tests that validate that Safeslab functions properly can be carried by running the benchmarks described in
the following section. 

## Evaluate

In the following we provide instructions for how to reproduce our paper's major experiments, namely performance
evaluation, illustrated in Figures 3 and 4 and described in Section 6.1 in our paper, and memory evaluation, shown in
Table 1 and described in Section 6.2 in our paper. We only describe how to reproduce the results of the "full" variant
from Figures 3 and 4 in our paper (green and turquoise bars, respectively), since it evaluates Safeslab with all of its
security features enabled, while the other variant was meant to analyze the overhead of one specific Safeslab feature.

Note that experiments conducted in a virtualized environment might exhibit slight variations compared to those conducted
bare-metal, due to several factors such as virtualization, activity on the host, etc. To minimize that, we recommend
disabling frequency scaling, turbo boost, swapping, and any other features or tasks on the host that might interfere
with the experiments in the guest. For that, we provide the script `./tools/cpu-for-bench.sh`, which executes a set of
commands that adjust system settings to facilitate low-noise benchmarking, and `./tools/cpu-for-dev.sh`, which reverts
them into a default state (not necessarily the previous one). Please adjust the parameters used by the script to fit
your CPU's frequency ranges. Also, note that executing these scripts requires `sudo` rights.

In addition, we also provide scripts for that automate computing the normalized overheads of the three experiments as
presented in our paper, as well as the geomean over all tests of an experiment (where applicable). 

### Performance

#### LMBench

Section 6.1.1 in our paper describes the performance results of Safeslab on the LMBench micro-benchmark, which provides
a set of tests that stress the underlying OS kernel. Figure 3 illustrates the results of this experiment. In order to
conduct this experiment, execute the following command from the root directory of this repository:

```shell
./tools/safeslab run performance lmbench
```

This will spawn a Qemu VM, run the LMBench tests listed in `./tools/run-lmbench.sh` both on the vanilla (baseline)
kernel and on Safeslab, and output the results in `./results/lmbench-{vanilla,safeslab}.log`. To obtain the normalized
results as presented in Figure 3 in our paper, execute the following:

```shell
./tools/compute-overheads-lmbench.sh ./results/lmbench-vanilla.log ./results/lmbench-safeslab.log
```

#### Phoronix Test Suite

Section 6.1.2 in our paper describes the performance results of Safeslab on the Phoronix Test Suite, which provides a
set of macro-benchmarks that resemble real-world payloads. Figure 4 illustrates the results of this experiment. In order
to conduct this experiment, execute the following command from the root directory of this repository:

```shell
./tools/safeslab run performance pts
```

This will spawn a Qemu VM, run the PTS tests listed in `./tools/run-pts.sh` both on the vanilla (baseline) kernel and on
Safeslab, and output the results in `./results/pts-{vanilla,safeslab}.log`. Sadly, the `compile-linux` test from PTS
leads to occasional crashes on Safeslab, therefore, we are excluding it from this experiment. To obtain the normalized
results as presented in Figure 4 in our paper, execute the following:

```shell
./tools/compute-overheads-pts.sh ./results/pts-vanilla.log ./results/pts-safeslab.log
```

### Memory

Section 6.2 in our paper describes the memory overhead of selected tests from the Phoronix Test Suite on Safeslab. Table
4 shows the results of this experiment. In order to conduct this experiment, execute the following command:

```shell
./tools/safeslab run membench
```

This will run the PTS tests listed in `./tools/run-membench.sh`, load/unload our custom kernel module to read memory
statistics in between each test, both on the vanilla (baseline) kernel and on Safeslab, and output the results in
`./results/membench-{vanilla,safeslab}.log`. Note that the first result is the system's memory consumption during boot.
Sadly, the `Build-Linux` test from PTS leads to occasional crashes on Safeslab, therefore, we are excluding it from
this experiment. To obtain the normalized results as presented in Table 1 in our paper, execute the following:

```shell
./tools/compute-overheads-membench.sh ./results/membench-vanilla.log ./results/membench-safeslab.log
```

## Clean

To clean the `build` and the `results` directories, run (from the root directory of this repository):

```shell
./tools/safeslab clean all
```

`safeslab clean` can also clean individual directories in `build`. To see its usage, run:

```shell
./tools/safeslab clean help
```

## License

We release this software under the [GPLv2 License](./linux-6.2.0/LICENSES/preferred/GPL-2.0).
