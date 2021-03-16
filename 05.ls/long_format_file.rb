# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require 'etc'

class LongFormatFile
  attr_reader :nlink, :username, :groupname, :size, :blocks

  def initialize(dir, file)
    fs = File.stat(dir + file)
    # ファイルモードを８進文字列に変換し、文字列を得る
    @mode = get_mode_string(fs.mode.to_s(8))
    @nlink = fs.nlink.to_s
    @username = Etc.getpwuid(fs.uid).name
    @groupname = Etc.getgrgid(fs.gid).name
    @size = fs.size.to_s
    @mtime = fs.mtime.strftime('%_m %_d %H:%M')
    @basename = if dir.empty?
                  file
                else
                  File.basename(file)
                end
    @blocks = fs.blocks
  end

  # ファイルタイプ部分の文字列を得る
  def get_file_type_string(mode_string)
    case mode_string
    when '010'
      'p'
    when '020'
      'c'
    when '040'
      'd'
    when '060'
      'b'
    when '100'
      '-'
    when '120'
      'l'
    when '140'
      's'
    else
      '?'
    end
  end

  # パーミッション部分の文字列を得る
  def get_permission_string(mode_string)
    case mode_string
    when '7'
      'rwx'
    when '6'
      'rw-'
    when '5'
      'r-x'
    when '4'
      'r--'
    when '3'
      '-wx'
    when '2'
      '-w-'
    when '1'
      '--x'
    else
      '---'
    end
  end

  # ファイルモードの文字列を得る
  def get_mode_string(mode_string)
    # mode文字列を長さ7の文字列に右詰し、０でpaddingを詰める
    mode = mode_string.rjust(6, '0')
    "#{get_file_type_string(mode[0, 3])}#{get_permission_string(mode[3])}#{get_permission_string(mode[4])}#{get_permission_string(mode[5])}"
  end

  # 最高幅に合わせて、右寄せ・左寄せする
  def set_string_width(max_nlink, max_username, max_groupname, max_size)
    @nlink = @nlink.rjust(max_nlink)
    @username = @username.ljust(max_username)
    @groupname = @groupname.ljust(max_groupname)
    @size = @size.rjust(max_size)
  end

  # ロングフォーマットファイル形式の文字列を得る
  def long_format_file
    "#{@mode}  #{@nlink} #{@username}  #{@groupname}  #{@size} #{@mtime} #{@basename}"
  end
end
