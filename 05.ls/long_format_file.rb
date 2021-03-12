require 'etc'

class LongFormatFile
  attr_reader :nlink, :username, :groupname, :size, :blocks
  def initialize(dir, file)
    fs = File::stat(dir + file)
    # ファイルモードを８進文字列に変換し、文字列を得る
    @mode = get_mode_string(fs.mode.to_s(8))
    @nlink = fs.nlink.to_s
    @username = Etc.getpwuid(fs.uid).name
    @groupname = Etc.getgrgid(fs.gid).name
    @size = fs.size.to_s
    @mtime = fs.mtime.strftime("%_m %_d %H:%M")
    if dir.empty?
      @basename = file
    else
      @basename = File.basename(file)
    end
    @blocks = fs.blocks
  end

  # 最高幅に合わせて、右寄せ・左寄せする
  def set_string_width(max_nlink, max_username, max_groupname, max_size)
    @nlink = @nlink.rjust(max_nlink)
    @username = @username.ljust(max_username)
    @groupname = @groupname.ljust(max_groupname)
    @size = @size.rjust(max_size)
  end

  # 最終的に表示する文字列を得る
  def get_string
    string = @mode + "  " + @nlink + " " + @username + "  " + @groupname + "  " + @size + " " + @mtime + " " + @basename
  end

  # ファイルモードの文字列を得る
  def get_mode_string(mode_string)
    # mode文字列を長さ7の文字列に右詰し、０でpaddingを詰める
    mode = mode_string.rjust(6, "0")
    string = ""
    # ファイルタイプ部分の文字列を得る
    string += (
      mode[0, 3].eql?("010") ? "p" :
      mode[0, 3].eql?("020") ? "c" :
      mode[0, 3].eql?("040") ? "d" :
      mode[0, 3].eql?("060") ? "b" :
      mode[0, 3].eql?("100") ? "-" :
      mode[0, 3].eql?("120") ? "l" :
      mode[0, 3].eql?("140") ? "s" : "?")
    # パーミッション部分の文字列を得る
    string += get_permission_string(mode[3])
    string += get_permission_string(mode[4])
    string += get_permission_string(mode[5])
    string
  end

  # パーミッション部分の文字列を得る
  def get_permission_string(mode_string)
    mode_string.eql?("7") ? "rwx" :
    mode_string.eql?("6") ? "rw-" :
    mode_string.eql?("5") ? "r-x" :
    mode_string.eql?("4") ? "r--" :
    mode_string.eql?("3") ? "-wx" :
    mode_string.eql?("2") ? "-w-" :
    mode_string.eql?("1") ? "--x" : "---"
  end
end
