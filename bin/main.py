#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
Created on Tue May 15, 2018 10:24:00
@author: Constellation Brands
'''

from cbi_ds_common.setup import config

from project_common import ProjectDefaults

from main_audit import execute as audit
from main_data import execute as data
from main_model import execute as model
from main_rules import execute as rules
from main_integration import execute as integration


class Defaults(ProjectDefaults):
    """
    Defaults
    """
    # arg1 = 1

    # LOCAL DEVELOPER OPTIONS


    # REQUIRED STATIC VALUES
    process = 'PROCESS'

def execute(cfg, arg1=None, arg2=False, **extra):
    """
    Main workflow of Project to coordinate the steps of the project

    Arguments:

    """

    cfg.log.push_prefix(Defaults.process)
    data(cfg, **extra)
    model(cfg, **extra)
    rules(cfg, **extra)
    audit(cfg, **extra)
    integration(cfg, **extra)
    cfg.log.pop_prefix()


def main():
    """
    Main Call for Project Workflow
    """

    cfg, func_args = config(Defaults)
    execute(**func_args)
    cfg.done()


if __name__ == '__main__':
    main()
    exit(0)
