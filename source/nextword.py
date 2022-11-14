"""
For given text build a dictionary of words and for each a list of any subsequent words in the same sentence in descending 
order of occurance such that the first word in each list is word's most common next word.
(Book text cut/paste from www.guthenburg.org into <samename>.txt files.)

Args:
	None

Returns:
	Dictionary of dictionaries

Raises:
	None
"""

import random, re

dictionary = {}

# these three texts between them provide a dictionary of some 26,000+ words
titles = ("Pride and Prejudice.txt","Metamorphasis.txt","War and Peace.txt")

for title in titles:

    book = open(title)

    text = book.read()

    book.close()

    text = text.replace("\n\n", "\n")

    sentences = re.split(r'[\n\.\?!]', text)

    for sentence in sentences:
        words = re.findall(r'[^\s!,.?":;0-9]+', sentence)
        for index, word in enumerate(words):
            if not word in dictionary:
                dictionary[word] = {}
            if index < len(words) - 1:
                next_word = words[index+1]
                if next_word in dictionary[word]:
                    dictionary[word][next_word] += 1
                else:
                    dictionary[word][next_word] = 1
                
# sort each word's list of next words in descening order so the most common next work is the first word in that word's list of next words
# sorted returns a list sorted in descending order of occurance because we specify key=dictionary[word].get and reverse=True
# the get method of the dictionary object returns the value of that item which in this case is the occurance of the word which is the key

for word in dictionary:
    dictionary[word] = sorted(dictionary[word], key=dictionary[word].get, reverse=True)

print(dictionary)

# build a sentence based on the most common next word of a given first word

word = input("your first word? ")

length = input("number of words? ")

if word in dictionary:

    words = [word]

    for n in range(int(length)):
        for word in dictionary[word]:
            if word not in words:
                words.append(word)
                break

    sentence = ""

    for word in words:
        sentence = sentence + word + " "
    
    print(sentence)

# build a sentence based on randomly selected first word

random.seed()

word = random.choice(list(dictionary.keys()))

if word in dictionary:

    words = [word]

    for n in range(int(length)):
        # if word's list of next words is not empty then
        if bool(dictionary[word]):
            # choose random word from list of possibilities
            word = random.choice(dictionary[word])
            words.append(word)

    sentence = ""

    for word in words:
        sentence = sentence + word + " "
    
    print(sentence)
