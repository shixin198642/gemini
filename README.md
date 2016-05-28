最近写了一个小工具，用来替代xRelease，觉得挺方便的，share给大家，希望能帮助大家提高点发布项目的效率，节省时间:
git   : git@git.n.xiaomi.com:shixin/gemini.git
email : shixin@xiaomi.com

我们在开发项目的时候，每天要把开发中的项目部署到onebox进行测试，但是老xRelease有自己的缺点：
- 配置复杂，配置文件分布在各个目录下，新同事在发布遇到问题的时候很难追踪问题
- 拷贝项目冗余，以micloud项目为例，在发布GalleryService的时候，它会把整个micloud-all项目都拷贝，浪费时间
- 编译项目冗余，每次都编译依赖的项目，即使依赖没有更改，还是要重新编译打包，浪费时间
- 不能发布项目到本地
- 代码在svn中，好多新入职的同学找不到该项目，而且项目中老旧的配置和多


和xRelease相比，Gemini有如下的优点：
- 配置简单，只有一个配置文件。

如下是GallerySyncService的配置文件(mt service):
----------------------------
SERVICE_NAME = GallerySyncService
SERVICE_TYPE = mt
RELEASE_PROJECT = MicloudMidTier
COMPILE_ARG = GallerySyncService=true
RELEASE_DIR = target/appassembler
-----------------------------

如下是GalleryAPI的配置文件(fe service):
-----------------------------
SERVICE_NAME = GalleryAPI
SERVICE_TYPE = fe
RELEASE_PROJECT = MicloudAPI
COMPILE_ARG = MicloudAPI-Gallery=true
RELEASE_DIR = target/MicloudAPI-0.0.1-SNAPSHOT
-----------------------------

2. 不进行本地拷贝工作
对于micloud这样已经很庞大，而且会越来越庞大的项目来说很有用，只编译需要的项目，以上面的项目为例：
sh release.sh GallerySyncService // 默认发布只编译MicloudMider项目, 不编译依赖
sh release.sh -f GallerySyncService //如果在发布的时候加上-f参数，则会编译在maven module中有依赖的项目

3. 发布项目到本地：
有的时候不需要把项目发布到onebox, 因为本机也部署有运行环境，所以Gemini也支持发布项目到本机，e.g.
sh release-local.sh GallerySyncService

4. 全平台支持
目前支持os x, linux，windows(需要安装cygwin，并在path环境变量中把cygwin目录放在最前面)