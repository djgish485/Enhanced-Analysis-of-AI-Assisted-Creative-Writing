from sfi import Data
import numpy as np
import dat
import os
import random


random.seed(1234)

genai_folder = os.path.join(os.path.expanduser("~"),"Desktop","GenAI_creativity_scripts")
dat_files_folder = os.path.join(genai_folder, "scripts", "words_glove")
model_file = os.path.join(dat_files_folder, "glove.840B.300d.txt")
dictionary_file = os.path.join(dat_files_folder, "words.txt")

model = dat.Model(model=model_file, dictionary=dictionary_file)

words_data = [np.array(Data.get(f"dat_word{i+1}")) for i in range(10)]

for i, word in enumerate(words_data[0]):
    words_set = [words_data[j][i] for j in range(10)]
    dat_value = model.dat(words_set)
    if dat_value is None:
        continue
    Data.storeAt("dat",i,dat_value)

# output_check = np.array(Data.get("dat"))
# print(output_check)