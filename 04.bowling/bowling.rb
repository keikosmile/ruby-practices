#!/usr/bin/env ruby

def bowling(score)
  # 1投毎に分割する
  scores = score.chars

  # 数字に変換
  shots = []
  shots_number = 0
  scores.each do |s|
    # ストライク
    if s == 'X'
      shots << 10
      # 9フレーム以下の１投目がストライク
      if shots_number < 18 && shots_number.even?
        shots << 0
        shots_number += 1
      end
    else
      shots << s.to_i
    end
    shots_number += 1
  end

  # フレーム毎に分割
  frames = []
  shots.each_slice(2) do |s|
    frames << s
  end

  # 10要素目があれば、９要素目(10フレーム）と連結して削除
  if frames[10]
    frames[9].concat(frames[10])
    frames.delete_at(10)
  end

  # ポイントを計算
  point = 0
  frames.each.with_index do |frame, i|
    # 10フレーム目は、フレームの単なる合計
    if i == 9
      point += frame.sum
    else
      # ストライク
      if frame[0] == 10
        # 次のフレームの１投目を加算
        point += 10 + frames[i + 1][0]
        # 次のフレームの１投目がストライクで、現在７フレーム以下
        if frames[i + 1][0] == 10 && i < 8
          # 次の次のフレームの１投目を加算
          point += frames[i + 2][0]
        else
          # 次のフレームの２投目を加算
          point += frames[i + 1][1]
        end
      # スペア
      elsif frame.sum == 10
        # 次のフレームの１投目を加算
        point += 10 + frames[i + 1][0]
      else
        # フレームの単なる合計
        point += frame.sum
      end
    end
  end

  point
end

# 引数として与えられた文字列で計算する
puts bowling(ARGV[0])
