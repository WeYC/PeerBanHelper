#!/bin/bash
set -euo pipefail

# 可通过环境变量覆盖以下项
GROUPID="${GROUPID:-com.ghostchu.peerbanhelper.external-libs}"
ARTIFACTID="${ARTIFACTID:-sqlite-jdbc-loongarch64}"
VERSION="${VERSION:-3.47.0.0}"
WORKDIR="/work"
TMPDIR="/tmp/sqlite-jdbc-build"

echo "Build settings:"
echo " GROUPID=${GROUPID}"
echo " ARTIFACTID=${ARTIFACTID}"
echo " VERSION=${VERSION}"
echo " WORKDIR=${WORKDIR}"
echo " TMPDIR=${TMPDIR}"

rm -rf "${TMPDIR}"
git clone --depth 1 https://github.com/xerial/sqlite-jdbc.git "${TMPDIR}"
cd "${TMPDIR}"

# 编译 sqlite-jdbc（在 armv7 容器中运行此脚本）
mvn -DskipTests package

# 找到生成的 jar（取 target 下的第一个 jar）
JAR=$(ls target/*.jar | head -n 1 || true)
if [ -z "${JAR}" ]; then
  echo "ERROR: sqlite-jdbc jar not found in target/"
  ls -la target || true
  exit 1
fi

echo "Found jar: ${JAR}"
mkdir -p "${WORKDIR}/lib"
# 把生成的 jar 拷贝到 repo 工作目录 lib/
cp -v "${JAR}" "${WORKDIR}/lib/sqlite-jdbc-linux-armv7.jar"

# 把 jar 安装到本地 m2 仓库（注意：我们把生成的 armv7 jar 安装到与 pom 中期望坐标一致的位置，
# 以便 maven 在构建 PeerBanHelper 时能从文件依赖库读取到这个本地替换包）
mkdir -p "${WORKDIR}/m2-local-repo"
mvn install:install-file \
  -DgroupId="${GROUPID}" \
  -DartifactId="${ARTIFACTID}" \
  -Dversion="${VERSION}" \
  -Dpackaging=jar \
  -Dfile="${WORKDIR}/lib/sqlite-jdbc-linux-armv7.jar" \
  -DlocalRepositoryPath="${WORKDIR}/m2-local-repo"

# 另外也以通用 org.xerial 坐标再安装一份（以覆盖任何可能引用 org.xerial:sqlite-jdbc 的情况）
mvn install:install-file \
  -DgroupId=org.xerial \
  -DartifactId=sqlite-jdbc \
  -Dversion="${VERSION}" \
  -Dpackaging=jar \
  -Dfile="${WORKDIR}/lib/sqlite-jdbc-linux-armv7.jar" \
  -DlocalRepositoryPath="${WORKDIR}/m2-local-repo"

echo "Installed to ${WORKDIR}/m2-local-repo"
ls -la "${WORKDIR}/m2-local-repo" || true
