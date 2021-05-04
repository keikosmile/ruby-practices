# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

# Wcクラスで用いるオプションのクラス
class Option
  # lwcm オプションを格納するハッシュ
  attr_accessor :option_hash

  # Optionオブジェクトの作成
  def initialize
    @option_hash = { l: false, w: false, c: false, m: false }
    @total_hash = { l: 0, w: 0, c: 0, m: 0 }
  end

  # オプションが指定されていない場合、デフォルトでl（行数）、w（単語数）、c（バイト数）オプションを設定するメソッド
  def set_option_default
    @option_hash = { l: true, w: true, c: true } if @option_hash == { l: false, w: false, c: false, m: false }
  end

  # 標準入力か１ファイルから読み込んだ文字列に対し、lwcm各オプションを適用し、得られた文字列を返すメソッド
  # ==== 引数
  # * +buf+ 標準入力か１ファイルから読み込んだ文字列
  # ==== 戻り値
  # * +string+ 標準入力か１ファイルから読み込んだ文字列に対し、lwcm各オプションを適用し、得られた文字列
  def apply_option(buf)
    string = ''
    string += apply_l_option(buf) if @option_hash[:l]
    string += apply_w_option(buf) if @option_hash[:w]
    string += apply_c_option(buf) if @option_hash[:c]
    string += apply_m_option(buf) if @option_hash[:m]
    string
  end

  # 標準入力か１ファイルから読み込んだ文字列に対し、lオプションを適用し行数を返すメソッド
  # ==== 引数
  # * +buf+ 標準入力か１ファイルから読み込んだ文字列
  # ==== 戻り値
  # * +n_line+ 行数（8桁右揃えの文字列に整形されている）
  def apply_l_option(buf)
    # 行数を数える（@bufが不正なバイト列を含む場合?に置き換える）
    n_line = buf.scrub.count("\n")
    # total値に加算する
    @total_hash[:l] += n_line
    # 8桁右揃えの文字列に整形して返す
    n_line.to_s.rjust(8)
  end

  # 標準入力か１ファイルから読み込んだ文字列に対し、wオプションを適用し単語数を返すメソッド
  # ==== 引数
  # * +buf+ 標準入力か１ファイルから読み込んだ文字列
  # ==== 戻り値
  # * +n_word+ 単語数（8桁右揃えの文字列に整形されている）
  def apply_w_option(buf)
    # 文字列がascii文字だけの場合
    if buf.ascii_only?
      # 文字列を空白文字で区切られた配列に分解し、要素数を得る
      n_word = buf.split.count
    else
      # 各空白文字を16進数のバイト単位で表した配列
      # 空白    ' ' : 0x20
      # 改頁    \f  : 0x0C
      # 改行    \n  : 0xA
      # 復帰    \r  : 0x0D
      # 水平タブ \t  : 0x09
      # 垂直タブ \v  : 0x0B
      # ノーブレークスペース  : 0x85
      wspace_array = %w[20 0C A 0D 09 0B 85]

      # 文字列をUTF-8で符号化してバイト単位の配列に分割し、16進数表記に変換する
      buf_array = buf.bytes.map do |b|
        b.to_s(16).upcase
      end
      # 空白文字で区切られた単語数を数える
      word_flag = 1
      n_word = 0
      buf_array.each do |b|
        if wspace_array.include?(b)
          word_flag = 1
        elsif word_flag == 1
          word_flag = 0
          n_word += 1
        end
      end
    end
    # total値に加算する
    @total_hash[:w] += n_word
    # 8桁右揃えの文字列に整形して返す
    n_word.to_s.rjust(8)
  end

  # 標準入力か１ファイルから読み込んだ文字列に対し、cオプションを適用しバイト数を返すメソッド
  # ==== 引数
  # * +buf+ 標準入力か１ファイルから読み込んだ文字列
  # ==== 戻り値
  # * +n_bytesize+ バイト数（8桁右揃えの文字列に整形されている）
  def apply_c_option(buf)
    # バイト数を数える（文字列のバイト長を整数で返す）
    n_bytesize = buf.bytesize
    # total値に加算する
    @total_hash[:c] += n_bytesize
    # 8桁右揃えの文字列に整形して返す
    n_bytesize.to_s.rjust(8)
  end

  # 標準入力か１ファイルから読み込んだ文字列に対し、mオプションを適用し文字数を返すメソッド
  # ==== 引数
  # * +buf+ 標準入力か１ファイルから読み込んだ文字列
  # ==== 戻り値
  # * +n_size+ 文字数（8桁右揃えの文字列に整形されている）
  def apply_m_option(buf)
    # 文字数を数える（マルチバイト文字1文字を1文字と数える）
    n_size = buf.size
    # total値に加算する
    @total_hash[:m] += n_size
    # 8桁右揃えの文字列に整形して返す
    n_size.to_s.rjust(8)
  end

  # lwcm各オプションのtotal値を文字列で返すメソッド
  # ==== 戻り値
  # * +string+ lwcm各オプションのtotal値（8桁右揃えの文字列に整形されている）からなる文字列
  def write_total
    string = ''
    string += @total_hash[:l].to_s.rjust(8) if @option_hash[:l]
    string += @total_hash[:w].to_s.rjust(8) if @option_hash[:w]
    string += @total_hash[:c].to_s.rjust(8) if @option_hash[:c]
    string += @total_hash[:m].to_s.rjust(8) if @option_hash[:m]
    string += " total\n"
    string
  end
end
