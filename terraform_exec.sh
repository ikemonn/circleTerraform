# 引数で渡されたディレクトリのファイルが変更されたか？
 is_file_changed() {
   local environment=$1
   # 実行ステータスだけ取得したいので、grepの結果は出力しない
   git diff --name-only HEAD HEAD^ \
     | grep $environment/ >> /dev/null
   echo $?
 }

 # ファイルが変更されたディレクトリの配列を取得
 get_file_change_environment_list() {
   local environment
   for environment in ${ALL_ENVIRONMENT[@]}
   do
     if [ `is_file_changed $environment` == "0" ]; then
       # echo $environment
       FILE_CHANGE_ENVIRONMENT+=($environment)
     fi
   done
   echo ${FILE_CHANGE_ENVIRONMENT[@]}
 }

 # terraform planを与えられた環境で行う
 exec_terraform_plan_per_environment() {
   local environment_list=$@
   for environment in ${environment_list[@]}
   do
     echo "file change dir is ${environment}"
     cd $TERRAFORM_DIR/$environment
     eval export AWS_ACCESS_KEY_ID='${'$environment'_AWS_ACCESS_KEY}'
     eval export AWS_SECRET_ACCESS_KEY='${'$environment'_AWS_SECRET_KEY}'
     export TF_VAR_aws_access_key=$AWS_ACCESS_KEY_ID
     export TF_VAR_aws_secret_key=$AWS_SECRET_ACCESS_KEY
    #  export -p
     echo `pwd`
     terraform plan
     cd -
   done
 }

 main() {
   readonly ALL_ENVIRONMENT=("evaluation" "staging" "production")
   readonly EVALUATION="evaluation"
   readonly STAGING="staging"
   readonly PRODUCTION="production"
   readonly TERRAFORM_DIR="terraform/aws/"

   FILE_CHANGE_ENVIRONMENT=()

   # ファイルが変更された環境を取得
   file_change_environment=`get_file_change_environment_list`
   echo ${file_change_environment[@]}

   # ファイルが変更された環境でterraform planを実行
   for environment in ${file_change_environment[@]}
   do
     echo "file change dir is ${environment}"
     cd $TERRAFORM_DIR/$environment

     export AWS_ACCESS_KEY_ID='${'$environment'_AWS_ACCESS_KEY}'
     export AWS_SECRET_ACCESS_KEY='${'$environment'_AWS_SECRET_KEY}'
     export TF_VAR_aws_access_key=$AWS_ACCESS_KEY_ID
     export TF_VAR_aws_secret_key=$AWS_SECRET_ACCESS_KEY
     terraform remote config -backend=S3 -backend-config="bucket=example-terraform-state" -backend-config="key=terraform.tfstate"
     terraform remote pull

     echo $TF_VAR_aws_access_key
     echo $TF_VAR_aws_secret_key
    #  export -p
    #  echo `pwd`
     terraform plan
     printenv
     cd -
   done
 }
 main
