# cbi_ds_template
CBI Base repository structure

The repository that contains the standard setup and configuration of CBI Data Science Projects.

[ MASTER [![CircleCI](https://circleci.com/gh/ConstellationBrands/ds-template/tree/master.svg?style=shield&circle-token=d77a0b004b558fe2becef1f6dfc395e25eac2ba5)](https://circleci.com/gh/ConstellationBrands/ds-template)
| DEV [![CircleCI](https://circleci.com/gh/ConstellationBrands/ds-template/tree/dev.svg?style=shield&circle-token=d77a0b004b558fe2becef1f6dfc395e25eac2ba5)](https://circleci.com/gh/ConstellationBrands/ds-template) ]



# STRUCTURE
  ## .circleci - contains circle ci integration
  ## BIN - contains source code for the project
    ### process.py - main workflow source
    ### <repository name>.py - main source
    ### cbi_ds_template.py - main source
    ### __init__.py ??? REVIEW
  ## CFG - contains project specific configuration data used in the project
    ### config.yml
    ### env.yml:  used for environment
    ### requirements.txt:  Used to define library specific requirements.
  ## DATA - contains data used within the project
  ## ENV - contains enviromental specific configuration data used in the project
  ## LIB - contains CBI specific libraries used in the project
  ## MAN - contains documentation for the project
  ## TEST - contains tests for the project
    runtest.py
  ### setup.py   ??? REVIEW distutils  https://docs.python.org/2/distutils/setupscript.html
  ### .gitignore
  ### README.md
  ## PROCESS  ? Can we have under a directory
    ### DOCKERFILE
    ### data-science-fargate-service.yaml
    ### data-science-fargate-master.yaml


#PY FILES
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Sep  7 12:38:07 2017

@author: fractaluser
"""

# DATA
  ## S3 :
    * DEV:  <dev_bucket>
    * TEST: <test_bucket>
    * PROD: <prod_bucket>
  ### STRUCTURE:
            * <repo>/audit/<file>
            * <repo>/log/<file>
            * <repo>/data/<file>   ? remove??
            * <repo>/user/<file> ?(same as data/user)
            * <repo>/inbound/<file>
            * <repo>/outbound/<file>
            * <repo>/model/<file>
            * <repo>/results/<file>
            * <repo>/debug/<file>
            * <repo>/process/<file> ?(same as data/process)
            * <repo>/work/<file>
  ### FILENAME
        <repo>.<process>.<group>.<date>.<file>.<model>.<extentions>.<compression>
        i.e. (cbi_ds_wsgoals.201801)
        text should be  .csv
        compression? .gz, .zip

   ##
  ### INPUT FILES
    1) <FILENAME>
       FILENAME: <NAME>.CSV.GZ
       DESCRIPTION: <Enter description here>

  ### OUTPUT FILES
    1) <FILENAME>
       FILENAME: <NAME>.CSV.GZ
       DESCRIPTION: <Enter description here>

# ALGORITHM
  ### PREPROCESSING
  ### MODEL
  ### VALIDATION

# CODE
  ### DEPENDENCIES
  ### LIBRARIES
  ### TESTING
    1) Unit Tests - automatically ran in CircleCI
    2) Scenario Tests - audit function in process.py
    3) Regression Tests - X
