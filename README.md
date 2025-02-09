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

성능
----
### 정확도

#### v0.3
CNN 모델의 주요 하이퍼 파라미터는 분류하려는 음절의 좌/우 문맥의 크기를 나타내는 win 값과, 음절 임베딩의 차원을 나타내는 emb 값입니다. win 값은 {2, 3, 4, 5, 7, 10}의 값을 가지며, emb 값은 {20, 30, 40, 50, 70, 100, 150, 200, 300, 500}의 값을 가집니다. 따라서 이 두 가지 값의 조합은 6 x 10으로 총 60가지를 실험하였고 아래와 같은 성능을 보였습니다. 성능 지표는 정확률과 재현율의 조화 평균값인 F-Score입니다.

![](.github/img/win_emb_f.png)

win 파라미터의 경우 3 혹은 4에서 가장 좋은 성능을 보이며 그 이상에서는 오히려 성능이 떨어집니다. emb 파라미터의 경우 150까지는 성능도 같이 높아지다가 그 이상에서는 별 차이가 없습니다. 최 상위 5위 중 비교적 작은 모델은 win=3, emb=150으로 F-Score 값은 97.11입니다. 이 모델을 large 모델이라 명명합니다.

#### v0.4
[띄어쓰기 오류에 강건한 모델을 위한 실험](https://github.com/kakao/khaiii/wiki/%EB%9D%84%EC%96%B4%EC%93%B0%EA%B8%B0-%EC%98%A4%EB%A5%98%EC%97%90-%EA%B0%95%EA%B1%B4%ED%95%9C-%EB%AA%A8%EB%8D%B8%EC%9D%84-%EC%9C%84%ED%95%9C-%EC%8B%A4%ED%97%98)을 통해 모델을 개선하였습니다. v0.4 모델은 띄어쓰기가 잘 되어있지 않은 입력에 대해 보다 좋은 성능을 보이는데 반해 세종 코퍼스에서는 다소 정확도가 떨어집니다. 이러한 점을 보완하기 위해 base 및 large 모델의 파라미터를 아래와 같이 조금 변경했습니다.

* base 모델: win=4, emb=35, F-Score: 94.96
* large 모델: win=4, emb=180, F-Score: 96.71


### 속도

#### v0.3
모델의 크기가 커지면 정확도가 높아지긴 하지만 그만큼 계산량 또한 많아져 속도가 떨어집니다. 그래서 적당한 정확도를 갖는 모델 중에서 크기가 작아 속도가 빠른 모델을 base 모델로 선정하였습니다. F-Score 값이 95 이상이면서 모델의 크기가 작은 모델은 win=3, emb=30이며 F-Score는 95.30입니다.

속도를 비교하기 위해 1만 문장(총 903KB, 문장 평균 91)의 텍스트를 분석해 비교했습니다. base 모델의 경우 약 10.5초, large 모델의 경우 약 78.8초가 걸립니다.

#### v0.4
모델의 크기가 커짐에 따라 아래와 같이 base, large 모델의 속도를 다시 측정했으며 v0.4 버전에서 다소 느려졌습니다.

* base 모델: 10.8 -> 14.4
* large 모델: 87.3 -> 165


사용자 사전
----
신경망 알고리즘은 소위 말하는 블랙박스 알고리즘으로 결과를 유추하는 과정을 사람이 따라가기가 쉽지 않습니다. 그래서 오분석이 발생할 경우 모델의 파라미터를 수정하여 바른 결과를 내도록 하는 것이 매우 어렵습니다. 이를 위해 khaiii에서는 신경망 알고리즘의 앞단에 기분석 사전을 뒷단에 오분석 패치라는 두 가지 사용자 사전 장치를 마련해 두었습니다.

### 기분석 사전
기분석 사전은 단일 어절에 대해 문맥에 상관없이 일괄적인 분석 결과를 갖는 경우에 사용합니다. 예를 들어 아래와 같은 엔트리가 있다면,

입력 어절 | 분석 결과
--------|--------
이더리움* | 이더리움/NNP

문장에서 `이더리움`으로 시작하는 모든 어절은 신경망 알고리즘을 사용하지 않고 `이더리움/NNP`로 동일하게 분석합니다.

세종 코퍼스에서 분석 모호성이 없는 어절들로부터 자동으로 기분석 사전을 추출할 경우 약 8만 개의 엔트리가 생성됩니다. 이를 적용할 경우 약간의 속도 향상도 있어서 base 모델에 적용하면 약 9.2초로 10% 정도 속도 향상이 있었습니다.

기분석 사전의 기술 방법 및 자세한 내용은 [기분석 사전 문서](https://github.com/kakao/khaiii/wiki/%EA%B8%B0%EB%B6%84%EC%84%9D-%EC%82%AC%EC%A0%84)를 참고하시기 바랍니다.


### 오분석 패치
오분석 패치는 여러 어절에 걸쳐서 충분한 문맥과 함께 오분석을 바로잡아야 할 경우에 사용합니다. 예를 들어 아래와 같은 엔트리가 있다면,

입력 텍스트 | 오분석 결과 | 정분석 결과
---------|-----------|---------
이 다른 것 | 이/JKS + _ + 다/VA + 른/MM + _ + 것/NNB | 이/JKS + _ + 다르/VA + ㄴ/ETM + _ + 것/NNB

만약 khaiii가 위 "오분석 결과"와 같이 오분석을 발생한 경우에 한해 바른 분석 결과인 "정분석 결과"로 수정합니다. 여기서 "\_"는 어절 간 경계, 즉 공백을 의미합니다.

오분석 패치의 기술 방법 및 자세한 내용은 [오분석 패치 문서](https://github.com/kakao/khaiii/wiki/%EC%98%A4%EB%B6%84%EC%84%9D-%ED%8C%A8%EC%B9%98)를 참고하시기 바랍니다.


빌드 및 설치
----
khaiii의 빌드 및 설치에 관해서는 [빌드 및 설치 문서](https://github.com/kakao/khaiii/wiki/%EB%B9%8C%EB%93%9C-%EB%B0%8F-%EC%84%A4%EC%B9%98)를 참고하시기 바랍니다.


Contributing
----
khaiii에 기여하실 분들은 [CONTRIBUTING](CONTRIBUTING.md) 및 [개발자를 위한 가이드](https://github.com/kakao/khaiii/wiki#%EA%B0%9C%EB%B0%9C%EC%9E%90%EB%A5%BC-%EC%9C%84%ED%95%9C-%EA%B0%80%EC%9D%B4%EB%93%9C) 문서를 참고하시기 바랍니다.


License
----
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

