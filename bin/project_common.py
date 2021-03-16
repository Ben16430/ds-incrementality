#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
Created on Tue May 15, 2018 10:24:00
@author: Constellation Brands
'''

import sys

PROJECT_FILENAME = sys.argv[0].split('/')[-1]
PROJECT_PARAMETERS = {
    'reload' : ['r', bool],
    'arg1': ['a1', int],
    'arg2': ['a2', int]
}

class ProjectDefaults:
    """
    ProjectDefaults.
    """

    arg1 = None
    arg2 = None

    #STATIC VALUES
    parameters = PROJECT_PARAMETERS
    file = PROJECT_FILENAME
