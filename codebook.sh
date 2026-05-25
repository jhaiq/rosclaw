#!/bin/bash
echo '!!output-start-cell'
cd /home/jhq/work/code/claw_ws/rosclaw
pnpm install
pnpm build#!/bin/bash
echo '!!output-start-cell'
cd /home/jhq/work/code/claw_ws/rosclaw
cd docker
docker compose up#!/bin/bash
echo '!!output-start-cell'
cd /home/jhq/work/code/claw_ws/rosclaw
pnpm install          # 安装依赖
pnpm build            # 构建所有包
pnpm typecheck        # 类型检查（不输出文件）
pnpm clean            # 清理构建产物#!/bin/bash
echo '!!output-start-cell'
cd /home/jhq/work/code/claw_ws/rosclaw
### rosclaw安装依赖及构建
```bash
pnpm install          # 安装依赖
pnpm build            # 构建所有包
```

### 集成 rosclaw插件到openClaw
#### 挂载rosclaw插件到openClaw
##### 本地部署openclaw： 1. 在openClaw的`src/plugins`目录下创建一个软链接，指向rosclaw插件的目录
```bash
ln -s /path/to/rosclaw/packages/rosclaw_plugin src/plugins/
# 例如，如果rosclaw插件位于~/rosclaw/packages/rosclaw_plugin
ln -s ~/rosclaw/packages/rosclaw_plugin src/plugins/
```
##### docker部署openclaw： 1. 在docker-compose.yml中添加一个新的服务，挂载rosclaw插件的目录到openClaw容器内
```yaml
services:
  openclaw:
    # ... 其他配置 ...      
    volumes:
      - ./path/to/rosclaw/packages/rosclaw_plugin:/app/src/plugins/rosclaw_plugin
      # 例如，如果rosclaw插件位于~/rosclaw/packages/rosclaw_plugin
      - ~/rosclaw/packages/rosclaw_plugin:/app/src/plugins/rosclaw_plugin
    ```
####加载rosclaw插件
在openClaw的配置文件中，添加rosclaw插件的加载配置。例如，在
`config/plugins.yaml`中添加：
```yaml
plugins:
    - name: rosclaw_plugin
      type: rosclaw_plugin
      path: /app/src/plugins/rosclaw_plugin
      args: []
``` 
####
重新启动openClaw，使插件生效
```bash
docker compose restart openclaw
``` 
#### 验证rosclaw插件是否加载成功
查看openClaw的日志，确认rosclaw插件已成功加载
```bash
docker compose logs openclaw    
```
##### 失败日志：
2026-03-20T05:50:05.677+00:00 [plugins] plugin service failed (agiros-transport): Error: WebSocket error connecting to ws://agiros:9090
2026-03-20T05:50:07.232+00:00 [ws] Proxy headers detected from untrusted address. Connection will not be treated as local. Configure gateway.trustedProxies to restore local client detection behind your proxy.
2026-03-20T05:50:07.253+00:00 [ws] webchat connected conn=5be36229-7ea4-435c-ad74-fdb21b477e5c remote=127.0.0.1 client=openclaw-control-ui webchat v2026.3.13
2026-03-20T05:50:08.678+00:00 [gateway] AGIROS transport status: connecting
2026-03-20T05:50:08.681+00:00 [gateway] AGIROS transport status: disconnected
2026-03-20T05:50:08.682+00:00 [gateway] AGIROS transport status: disconnected

##### 成功日志：
2026-03-20T05:53:20.741+00:00 [gateway] AGIROS transport status: connected

### 启动agiros环境
```bash
source /opt/agiros/loong/setup.bash
source ~/rosclaw/install/setup.bash
``` 

###启动 rosbridge_server
```bash
agiros launch rosbridge_server rosbridge_server.launch.py
```

### 启动turtlebot3_gazebo
```bash
source /opt/agiros/pixiu/setup.bash
agiros launch turtlebot3_gazebo turtlebot3_world.launch.py
````

#### 启动日志
root@f8fcd141dd84:/agiros_ws# agiros launch turtlebot3_gazebo turtlebot3_world.launch.py
bash: agiros: command not found
root@f8fcd141dd84:/agiros_ws# source /opt/agiros/pixiu/setup.bash 
root@f8fcd141dd84:/agiros_ws# agiros launch turtlebot3_gazebo turtlebot3_world.launch.py

turtlebot3_gazebo界面
![turtlebot3_gazebo](turtlebot3_gazebo.png)


### openClaw webui中测试rosclaw插件
聊天中输入：
1. 请介绍一下你的能力，回复如下类似内容：我是一个rosclaw插件，能够与turtlebot3_gazebo进行通信。


2. 请测试一下你的能力。

输出：


3. 请控制turtlebot3向后移动，回复如下类似内容：正在控制turtlebot3向后移动。


 













### 启动 turtlebot3 世界
```bash
agiros launch turtlebot3_gazebo turtlebot3_world.launch.py
```
