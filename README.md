khaiii
======

khaiii is an abbreviation for "Kakao Hangul Analyzer III" and is the third morphological analyzer developed by Kakao. It inherits the naming convention from the second version of the morphological analyzer, dha2 (Daumkakao Hangul Analyzer 2).

In linguistics, a morpheme is the smallest unit of language that carries meaning and can be separated within speech. In other words, if further broken down, it loses its meaning. A morphological analyzer is software that segments words into their constituent morphemes. This process is a fundamental step in natural language processing (NLP) and serves as the foundation for subsequent processes such as syntax and semantic analysis. (Cited from Korean Wikipedia)

Build
-----

To build the project localy:

```shell
# Set CWD to build directory
mkdir build
cd build

# Install required dependencies with conan
conan profile detect
conan install .. --output-folder=. --build=missing 

# Prepare to build
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release -G"Ninja"

# Build
RUN cmake --build .
RUN cmake --build . --target large_resource
RUN cmake --build . --target package_python

# Install python package
cd package_python
pip3 install .
```

To build the project inside Docker:

```shell
docker build  -t khaiii docker
docker run --rm -it khaiii
```


Data-driven Approach
--------------------

Unlike previous versions, which relied on dictionaries and rule-based methods for analysis, khaiii utilizes data-driven (or machine learning-based) algorithms. The corpus used for training is the ["21st Century Sejong Project Final Outcome"](https://ithub.korean.go.kr/user/noticeView.do?boardSeq=1&articleSeq=16), distributed by the National Institute of the Korean Language. Kakao has corrected errors and made some additions to this dataset.

After filtering out sentences with errors in the preprocessing stage, we used a corpus consisting of approximately 850,000 sentences and 10 million word segments for training. For more details on the corpus and part-of-speech (POS) tagging system, please refer to the [corpus documentation](https://github.com/kakao/khaiii/wiki/%EC%BD%94%ED%8D%BC%EC%8A%A4).

Algorithm
---------

For machine learning, khaiii employs a Convolutional Neural Network (CNN), one of the neural network algorithms. Since morphological analysis is a fundamental preprocessing step in NLP, speed is a critical factor. Given this, we excluded Recurrent Neural Network (RNN) algorithms such as Long Short-Term Memory (LSTM), which are commonly used in NLP but are less efficient in terms of processing speed.

For a detailed explanation of the CNN model, please refer to the [CNN Model documentation](https://github.com/kakao/khaiii/wiki/CNN-%EB%AA%A8%EB%8D%B8).

Performance
-----------

### Accuracy

#### v0.3

The key hyperparameters of the CNN model are win, which represents the size of the left/right context of the syllable to be classified, and emb, which denotes the dimension of the syllable embedding. The win parameter takes values from {2, 3, 4, 5, 7, 10}, while the emb parameter takes values from {20, 30, 40, 50, 70, 100, 150, 200, 300, 500}. A total of 60 combinations (6 x 10) of these two parameters were tested, and the model achieved the following performance. The performance metric used is the F-Score, which is the harmonic mean of precision and recall.

![](.github/img/win_emb_f.png)

For the win parameter, the best performance was observed at values 3 or 4, with performance declining for larger values. Regarding the emb parameter, performance improved up to 150, after which there was no significant change. Among the top five models, the smallest model had win=3 and emb=150, achieving an F-Score of 97.11. This model is referred to as the large model.

#### v0.4

The model was further improved through experiments aimed at enhancing robustness to spacing errors ([Experiments on a Robust Model Against Spacing Errors](https://github.com/kakao/khaiii/wiki/%EB%9D%84%EC%96%B4%EC%93%B0%EA%B8%B0-%EC%98%A4%EB%A5%98%EC%97%90-%EA%B0%95%EA%B1%B4%ED%95%9C-%EB%AA%A8%EB%8D%B8%EC%9D%84-%EC%9C%84%ED%95%9C-%EC%8B%A4%ED%97%98)). The v0.4 model performs better on text with incorrect spacing, but its accuracy slightly decreases on the Sejong Corpus. To address this issue, the parameters of the base and large models were slightly adjusted as follows:

* Base model: win=4, emb=35, F-Score: 94.96
* Large model: win=4, emb=180, F-Score: 96.71


### Speed

#### v0.3

A larger model improves accuracy but also increases computational complexity, leading to slower processing speeds. Therefore, among models with reasonable accuracy, we selected a smaller, faster model as the base model. The smallest model with an F-Score above 95 was win=3, emb=30, achieving an F-Score of 95.30.

To compare processing speed, we analyzed a dataset of 10,000 sentences (total size: 903KB, average sentence length: 91 characters). The results were:

    Base model: ~10.5 seconds
    Large model: ~78.8 seconds

#### v0.4

As the model size increased, we re-measured the processing speed of the base and large models, finding that v0.4 is slightly slower than the previous version.

    Base model: 10.8 → 14.4 seconds
    Large model: 87.3 → 165 seconds

User Dictionary
---------------

Neural network algorithms are often referred to as black-box algorithms, meaning that it is difficult for humans to trace the reasoning process behind their results. As a result, when misanalysis occurs, it is very difficult to adjust model parameters to ensure correct results.

To address this issue, khaiii incorporates two user dictionary mechanisms:

    A pre-analysis dictionary, placed before the neural network.
    An error correction patch, applied after the neural network.

### Pre-Analysis Dictionary

The pre-analysis dictionary is used when a single word segment consistently has the same analysis result, regardless of context.

For example, if the dictionary contains the following entry:

Input Word Segment | Analysis Result
--------|--------
이더리움* | 이더리움/NNP

Then, all word segments starting with "이더리움" in a sentence will be directly analyzed as "이더리움/NNP", bypassing the neural network algorithm.

When extracting pre-analysis dictionary entries from the Sejong Corpus, selecting only words without ambiguity results in approximately 80,000 entries. Applying this dictionary also provides a slight speed improvement. In the base model, processing time improved by approximately 10%, reducing from 10.5 seconds to 9.2 seconds.

For more details on the pre-analysis dictionary and implementation, please refer to the [Pre-Analysis Dictionary Documentation](https://github.com/kakao/khaiii/wiki/%EA%B8%B0%EB%B6%84%EC%84%9D-%EC%82%AC%EC%A0%84).

### Error Correction Patch

The error correction patch is used when misanalysis needs to be corrected based on sufficient context across multiple word segments.

For example, consider the following entry:

Input Text | Misanalysis Result | Correct Analysis Result
---------|-----------|---------
이 다른 것 | 이/JKS + _ + 다/VA + 른/MM + _ + 것/NNB | 이/JKS + _ + 다르/VA + ㄴ/ETM + _ + 것/NNB

If khaiii produces the misanalysis result, the error correction patch will modify it to the correct analysis result. Here, "_" represents a word boundary (i.e., a space).

For more details on the error correction patch and implementation, please refer to the [Error Correction Patch Documentation](https://github.com/kakao/khaiii/wiki/%EC%98%A4%EB%B6%84%EC%84%9D-%ED%8C%A8%EC%B9%98).

Build & Installation
--------------------

For information on building and installing khaiii, please refer to the [Build & Installation Guide](https://github.com/kakao/khaiii/wiki/%EB%B9%8C%EB%93%9C-%EB%B0%8F-%EC%84%A4%EC%B9%98).

Contributing
------------

If you would like to contribute to khaiii, please refer to the [CONTRIBUTING document](CONTRIBUTING.md) and the [Developer Guide](https://github.com/kakao/khaiii/wiki#%EA%B0%9C%EB%B0%9C%EC%9E%90%EB%A5%BC-%EC%9C%84%ED%95%9C-%EA%B0%80%EC%9D%B4%EB%93%9C).


License
-------

This software is licensed under the [Apache 2 license](LICENSE), quoted below.

Copyright 2018 Kakao Corp. <http://www.kakaocorp.com>

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this project except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations under
the License.

