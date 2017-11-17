# tf-ecs-example-app

Example on how to use terraform modules within an application repository

## Local Development

``` bash

docker-compose up --build


```

## Separation Decisions

- A real world app would not have the VPC as module, but pull in some args only
- keep ASG & ECS separate
- kept Security Groups in ASG, would pull these out or at least make them configurable beyond defaults
