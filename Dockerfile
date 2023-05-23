FROM ruby:2.7.5

# Set environment variables
ENV APP_HOME /app
ENV BUNDLE_PATH /bundle

# Update the packages list and install dependencies
RUN apt-get update -qq && apt-get install -y poppler-utils tesseract-ocr wget ghostscript git

# Download, build and install ImageMagick
RUN wget https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.0-57.tar.gz && \
    tar xvf 7.1.0-57.tar.gz && \
    cd ImageMagick-7.1.0-57 && \
    ./configure && \
    make && \
    make install && \
    ldconfig /usr/local/lib

# Create and set the working directory
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

# Copy your app's code into the Docker image
COPY . $APP_HOME

# Install the application's dependencies
RUN bundle install
