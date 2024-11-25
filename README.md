### 前置工作

```bash
sudo apt install vim git curl unzip
```

#### 网络代理（可选）

```bash
cat <<EOT >> ~/.bashrc
export http_proxy=http://192.168.1.210:7890
export https_proxy=http://192.168.1.210:7890
EOT

source ~/.bashrc
```

#### 安装 Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo DOWNLOAD_URL=https://mirrors.ustc.edu.cn/docker-ce sh get-docker.sh
```

#### 安装依赖

```bash
sudo apt install genimage dosfstools mtools
```
