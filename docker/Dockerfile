# Builder
FROM debian:13.4-slim AS builder

LABEL org.opencontainers.image.authors="Agno"

ENV DEBIAN_FRONTEND=noninteractive \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:${PATH}"

# Update and install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        git \
        meson \
        ninja-build \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Clone the Khaiii repository from GitHub
RUN git clone --depth=1 --branch "master" "https://github.com/Agnoctopus/ModernKhaiii.git" /opt/khaiii

# Set working directory
WORKDIR /opt/khaiii

# Setup virtualenv
RUN python3 -m venv "${VIRTUAL_ENV}" && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Configure conan profile
RUN conan profile detect --force

# Setup build directory
RUN mkdir build
WORKDIR /opt/khaiii/build

RUN conan install .. \
        --output-folder=. \
        --build=missing
RUN cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -G Ninja

# Build
RUN cmake --build . --parallel
RUN cmake --build . --target large_resource --parallel
RUN cmake --build . --target package_python --parallel
RUN pip wheel \
        --no-cache-dir \
        --no-deps \
        --wheel-dir /tmp/wheels \
        /opt/khaiii/build/package_python

# Final image
FROM python:3.14-slim AS runtime

LABEL org.opencontainers.image.authors="Agno"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Update and install en_US.UTF-8 locale
RUN apt-get update && \
	    apt-get install -y --no-install-recommends \
		locales \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Copy worker build directory
COPY --from=builder /tmp/wheels /tmp/wheels

# Upgrade pip and install package
RUN pip install --no-cache-dir --root-user-action=ignore --upgrade pip
RUN pip install --no-cache-dir --root-user-action=ignore /tmp/wheels/*.whl
RUN rm -rf /tmp/wheels

CMD ["python3"]
