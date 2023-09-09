export   suffix="_KYP3.0.V202301.02.000"
export   s="subTask_product"${suffix}
export   f="feature"${suffix}
export   r="release"${suffix}
export   d=dev
export   o="origin/"
export   log="/Users/leiyunfeng/IdeaProjects/kyp/.idea/log.txt"
export   base="/Users/leiyunfeng/IdeaProjects/kyp"

function merge(){
  git checkout $1
  ## 拉取远程分支
  git pull
  git merge $o$2 -m "Merge remote-tracking branch '${o}${2}' into ${1}"
  ## 合并失败
  if [ $? -ne 0 ]; then
    ## 回滚合并
    git merge --abort
    ## 记录日志
    echo  ${3} ${1} "------">> $log
    return 1
  fi

  git push
  ## 如果$1是dev分支,则不打印成功日志
#  if [ $1 = $d ]; then
#    return 0
#  fi
  echo ${3} ${1} "++++++" >> $log
  return 0
}
## 合并subtask feature dev
## $1 项目路径 $2 项目名称
function mergeTotal() {
    ## 切换到项目路径
    cd $1
    ## 获取远程分支
    git fetch --all
    if git ls-remote --heads | grep -q $r; then
            merge $d $r $2
            git checkout $r
    else
            ## 有差异合并
            if git diff --quiet $o$s $o$f; then
            echo ${2} "======"  >> $log
            else
                  merge $s $f $2
                  merge $f $s $2
            fi
            merge $d $f $2
            git checkout $s
    fi
}
## 清空日志文件
"" > $log

##循环base路径下的git项目,并发mergeTotal操作
for dir in $(find $base -type d -name ".git"); do
  parent_dir=$(dirname "$dir")
  mergeTotal $parent_dir $(basename "$parent_dir") &
done

## 等待所有后台进程结束
wait
successNumber=$(grep -c "++++++" $log)
errorNumber=$(grep -c "\------" $log)
noChangeNumber=$(grep -c "======" $log)
terminal-notifier -title "kyp合并日志" -message "成功$successNumber,失败$errorNumber,无变化$noChangeNumber" -execute "open $log"
