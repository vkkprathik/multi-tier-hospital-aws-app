# Multi-Tier Hospital Application on AWS

A Hospital Management System deployed on AWS using a secure multi-tier architecture with Terraform.

## Overview

This project demonstrates deployment of a Flask web application on AWS EC2 with Amazon RDS as the database. Infrastructure was provisioned using Terraform.

## Architecture

- EC2 for application hosting
- RDS MySQL/PostgreSQL for database
- VPC with public/private subnets
- IAM for access management
- Security Groups for controlled traffic

## Technologies Used

- AWS EC2
- AWS RDS
- AWS VPC
- IAM
- Terraform
- Python Flask
- Linux
- GitHub

## Key Features

- Multi-tier architecture
- Infrastructure as Code
- Secure networking
- Application deployment
- Database integration

## Deployment

```bash
terraform init
terraform plan
terraform apply