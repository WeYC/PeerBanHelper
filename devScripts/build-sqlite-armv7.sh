#!/bin/bash
set -euo pipefail

# 可通过环境变量覆盖以下项
GROUPID="${GROUPID:-org.xerial}"
ARTIFACTID="${ARTIFACTID:-sqlite-jdbc-linux-armv7}"
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

# 用 Maven 构建 native jar（skip tests 加速）
# 注意：sqlite-jdbc 的构建可能会生成多个 jar，下面取 target 下的 jar
mvn -DskipTests package

# 找到生成的 jar（取第一个 jar 作为产物）
JAR=$(ls target/*.jar | head -n 1 || true)
if [ -z "${JAR}" ]; then
  echo "ERROR: sqlite-jdbc jar not found in target/"
  ls -la target || true
  exit 1
fi

echo "Found jar: ${JAR}"
mkdir -p "${WORKDIR}/lib"
cp -v "${JAR}" "${WORKDIR}/lib/sqlite-jdbc-linux-armv7.jar"

# 把 jar 安装到本地 m2 仓库（项目会把 m2-local-repo 复制到构建阶段）
mkdir -p "${WORKDIR}/m2-local-repo"
mvn install:install-file \
  -DgroupId="${GROUPID}" \
  -DartifactId="${ARTIFACTID}" \
  -Dversion="${VERSION}" \
  -Dpackaging=jar \
  -Dfile="${WORKDIR}/lib/sqlite-jdbc-linux-armv7.jar" \
  -DlocalRepositoryPath="${WORKDIR}/m2-local-repo"

echo "Installed to ${WORKDIR}/m2-local-repo"
ls -la "${WORKDIR}/m2-local-repo" || true
