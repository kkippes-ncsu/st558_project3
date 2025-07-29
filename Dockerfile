# Use a plumber-enabled R image
FROM rstudio/plumber

# Install system dependencies (optional: update based on actual needs)
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-gnutls-dev \
    libpng-dev \
    pandoc

# Install required R packages
RUN R -e "install.packages(c('caret', 'plumber', 'tidymodels', 'tidyverse', 'ranger'))"

# Copy all necessary files into the container
COPY API.R /app/
COPY diabetes_binary_health_indicators_BRFSS2015.csv /app/

# Set working directory
WORKDIR /app

# Expose plumber port
EXPOSE 8000

# Start plumber API
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb('API.R'); pr$run(host='0.0.0.0', port=8000)"]