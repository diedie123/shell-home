#shell

### 前置场景

* XX银行现场3.0微服务部署
* 测试环境两台机器，所有后端服务部署一台，前端服务部署一台
* 验证环境多达19台机器，除了注册中心和调度中心外每个服务需要部署四个节点
* 升级流程为，先升级测试环境后升级验证环境
* 测试环境和验证环境的网络畅通

### 解决思路

1. 先升级测试环境服务
2. 配置测试环境ssh免密登录所有验证服务器，方便执行ssh，scp命令
3. 验证环境的部署路径用户名都是一致的编写函数复用远程逻辑
   * 函数入参 $1验证环境ip，$2验证环境部署的模块用,隔开如kyp-frs,kyp-wms
   * ssh找到server路径下所有的shutdown.sh脚本，服务执行权限并关闭程序
   * 解析入参$2转成数组执行循环逻辑
   * ssh 将程序的applib文件夹重命名为时间戳到当前路径做备份（可优化到统一路径）
   * scp 将测试环境服务的applib包移动到验证环境的路径下
   * ssh启动远程服务
4. 封装调用shell脚本

### 源码

```shell
set -eu
function updateRemote(){
echo "$1:停止服务"
ssh wpsuser@$1 'find /home/wpsuser/server -name  shutdown.sh -exec chmod 755 {} \; -exec {} \;'
IFS=','read -ra data <<< "$2"
for module in "${data[@]}"
do 
	echo "$1:备份$module:lib"
	ssh wpsuser@$1 "mv /home/wpsuser/server/$module/applib /home/wpsuesr/server/$module/$(date +%s)"
	scp -qr /home/wpsuser/server/$module/applib wpsuser@$1:/home/wpsuser/server/$module/
done
	echo "$1:启动服务"
	ssh wpsuser@$1 'find /home/wpsuser/server -name startup.sh -exec chmod 755 {} \; -exec {} \;' &
}

updateRemote ip1 kyp-frs,kyp-wms &
updateRemote ip2 kyp-frs,kyp-wms &
updateRemote ip3 kyp-frs,kyp-wms &
updateRemote ip4 kyp-frs,kyp-wms &

updateRemote ip5 kyp-scheduler,kyp-rigister &
...
```

### 总结

1. 上述脚本需要结合现场使用，不具备通用性
2. ssh配置免密登录然后执行ssh命令和scp传输具有通用性，可借鉴本脚本完成现场脚本搭建
3. 可以将函数放到.bashrc中可以直接在命令行中直接调用，方便单个模块升级
4. 将其中的关闭服务，启动服务可封装独立脚本便于统一关闭启动服务
5. 上述升级只升级了applib，保留了源程序的config与sbin不会覆盖配置文件，kyp-XXX-bootstrap.jar没有覆盖，因为一般不修改，做了偷懒处理
6. 升级前端代码和python脚本可借鉴上述实现
7. 编写脚本后先在服务上单条执行验证，切记不可一把梭
8. ssh免密登录后首次使用ssh登录会有个提醒输入yes，建议先做好连通性测试后然后统一执行脚本
9. 正确评估编写脚本是否能给你省下时间，如果有必要就放手去干，浙商现场起码升级了10+次，cover住了编写代码的服务，且脚本执行减少了人工出错的可能
10. 编写脚本多问问gpt老师，感谢gpt老师的帮助，推荐使用poe，回答问题比较快🙆🏻‍♀️
