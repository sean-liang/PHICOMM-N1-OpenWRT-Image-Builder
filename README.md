# 斐讯N1盒子OpenWRT镜像自动构建脚本

## 使用方法：

1. `git clone https://github.com/sean-liang/PHICOMM-N1-OpenWRT-Image-Builder.git`
2. 准备支持N1盒子的Armbian镜像，放入当前目录，建议重命名为`armbian.img`
3. 准备编译好的OpenWRT镜像，放入当前目录，建议重命名为`openwrt.img`
4. 将需要初始化的配置与文件放入`files`文件夹 
5. 运行`sudo build.sh`，构建的最终镜像为`n1-firmware.img.gz`，大小为500M左右
6. 使用[balenaEtcher](https://www.balena.io/etcher/)一类的工具将镜像写入u盘

## Armbian镜像

### 下载地址

建议从[https://yadi.sk/d/pHxaRAs-tZiei](https://yadi.sk/d/pHxaRAs-tZiei)下载最新的支持Amlogic S905的stretch镜像，在本说明写作时最新的镜像为：`Armbian_19.11.3_Aml-g12_stretch_legacy_5.3.0_20191126.img.xz`

### 选择设备为斐讯n1盒子

如果使用的是上边提到的`Armbian_19.11.3_Aml-g12_stretch_legacy_5.3.0_20191126.img.xz`，默认已经选择n1盒子了，可以省略下边的步骤。

* 挂载镜像的boot分区：	
	* `sudo mkdir -p /media`
	* `LOOP_DEV="$(sudo losetup -P -f --show armbian.img)"`
	* `sudo mount "$LOOP_DEV"p1 /media`
* 检查`/media/uEnv.ini`文件中的`dtb_name`是否为`meson-gxl-s905d-phicomm-n1.dtb`，如果不是，可以到`/media/dtb`目录下找到n1的dtb的路径并修改`uEnv.ini`文件
* 写入并取消挂载镜像：
	* `cd & sudo sync` 
	* `sudo umount /media`
	* `sudo losetup -d $LOOP_DEV`

### OpenWRT镜像

* 建议使用[Lean的OpenWRT源](https://github.com/coolsnowwolf/lede)
* 编译环境的搭建与编译方法见其说明
* `Target System`选择`Broadcom BCM27xx`，`Subtarget`选择`BCM2710 boards (64 bit)`，`Target Profile`选择`Raspberry Pi 2B-1.2/3B/3B+/3CM`
* `Target Image`需要勾选`ext4`
* 编译之后的镜像：`bin/targets/brcm2708/bcm2710/openwrt-brcm2708-bcm2710-rpi-3-ext4-factory.img.gz`
* 解压：`gunzip openwrt-brcm2708-bcm2710-rpi-3-ext4-factory.img.gz`得到OpenWRT的镜像文件：`openwrt-brcm2708-bcm2710-rpi-3-ext4-factory.img`

### 初始配置

初始配置与程序在`files`文件夹下：

* `etc/modules.d/wireless_enable`：无线硬件的设置，原地址[https://github.com/maxlicheng/phicomm-n1-wireless](https://github.com/maxlicheng/phicomm-n1-wireless)，不要删除
* `etc/config/network`：网络接口配置，默认IP为`192.168.1.254`，网关`192.168.1.1`，DNS`114.114.114.114`
* `etc/config/dhcp`：DHCP配置，默认关闭DHCP服务
* `etc/config/wireless`：无线网络配置，默认关闭无线网络

`etc/config`下的文件可以删除，路由第一次启动会自动生成默认的配置文件。

可以把当前路由的备份文件合并到`files`中。