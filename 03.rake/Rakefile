require 'rake/clean'

# タスクの説明を入れる
desc 'hello.cとmessage.cをコンパイルするタスクです。'

CC = "gcc"

# コンパイル対象をこのディレクトリ以下にある全ての.cファイルとする
SRCS = FileList["**/*.c"]
OBJS = SRCS.ext('o')

# 一時ファイルの削除
CLEAN.include(OBJS)
# 生成された全てのファイルの削除
CLOBBER.include("hello")

# defaultのタスクを定義する
task :default => "hello"

file "hello" => OBJS do |t|
  sh "#{CC} -o #{t.name} #{t.prerequisites.join(' ')}"
end

# 拡張子'o'ファイルを作成するために拡張子'c'ファイルが必要というルールを定義する
rule '.o' => '.c' do |t|
  sh "#{CC} -c #{t.source}"
end
