#!/usr/bin/env ruby

# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

# １投ずつのスコア文字列を数字配列に変換
def to_shots(scores)
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
  shots
end

# 数字配列をフレーム毎に分割
def to_frames(shots)
  frames = []
  shots.each_slice(2) do |s|
    frames << s
  end

  # 10要素目があれば９要素目(10フレーム）と連結し削除
  if frames[10]
    frames[9].concat(frames[10])
    frames.delete_at(10)
  end
  frames
end

# ポイントを計算
def calc_point(frames)
  point = 0
  frames.each.with_index do |frame, i|
    # フレームの合計を加算
    point += frame.sum
    # １〜９フレームでスペアかストライク
    if frame.sum == 10 && i < 9
      # 次のフレームの１投目を加算
      point += frames[i + 1][0]
      # ストライク
      if frame[0] == 10
        # １〜８フレームで次のフレームもストライク
        point = if frames[i + 1][0] == 10 && i < 8
                  # 次の次のフレームの１投目を加算
                  point + frames[i + 2][0]
                else
                  # 次のフレームの２投目を加算
                  point + frames[i + 1][1]
                end
      end
    end
  end
  point
end

def bowling(score)
  # スコア文字列を1投ずつに分割
  scores = score.chars
  # 一投ずつのスコア文字列を数字配列に変換
  shots = to_shots(scores)
  # 数字配列をフレーム毎に分割
  frames = to_frames(shots)
  # ポイントを計算
  calc_point(frames)
end

# 引数として与えられた文字列で計算する
puts bowling(ARGV[0])
