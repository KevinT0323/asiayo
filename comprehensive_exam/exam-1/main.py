from collections import Counter
import re

def most_frequent_word(filename):
    with open(filename, 'r', encoding='utf-8') as file:
        text = file.read().lower() # 轉換為小寫

    words = re.findall(r'\b[a-z]+\b', text) # 只保留純英文字母，移除標點符號

    counter = Counter(words)
    most_common = counter.most_common(1)[0] # 取出出現次數最多的單字
    print(most_common[1], most_common[0])

most_frequent_word('words.txt')
