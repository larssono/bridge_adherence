# Bridge Adherence
This Github Repository is used to run adherence data using Bridge API with R. 

## How to Run:

### 1. Environment Requirements
To copy the environment, you will require: 
- [R Renv Environment](https://rstudio.github.io/renv/articles/renv.html)
- [Synapse Authentication](https://help.synapse.org/docs/Quick-Start:-Setting-Up-a-Project.2055471258.html)

### 2. Create Environment:
```R
library(renv)
renv::init(bare = T) # create clean envronment
renv::restore() # restore environment
```

### 3. Parameters:
You will only required to change several parameters, as follows:

#### a. Bridge Authentication:
```R
#' log in to bridge using bridgeclient
bridgeclient::bridge_login(
    study = "mobile-toolbox",
    credentials_file = ".bridge_creds")
```
Change credentials_file in .bridge_creds to your credentials from [requested account](https://docs.google.com/forms/d/e/1FAIpQLSfZAQwhaUjrgK73pU2XtD7PUCXEtoUOj3g0i2luSUlNQhGq8g/viewform), change study to your desired Bridge Study.

#### b. Output Reference:
```R
#' output reference in synapse
OUTPUT_REF <- list(
    filename = <change to desired filename for adherence output>
    parent_id = <synapse parent ID location>
    ...
)
```



