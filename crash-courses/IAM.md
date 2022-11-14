# Crash crourse in IAM
IAM is a service that allows you to manage users and their access to the AWS. It is a central part of the AWS security model. It is also a very complex service, and it is easy to get lost in the details. This document is a crash course in IAM, and it is intended to give you a good overview of the service, and to help you understand how to use it.

## Users
Users are the main actors in IAM. They are the people who use AWS. Users can be human or non-human. For example, you can create a user for a service that runs on EC2. Users can be assigned to groups, and they can have policies attached directly. Policies define what the user can do in AWS. Policies can be attached directly to users, or they can be attached to groups. When a user is a member of a group, the policies attached to the group are inherited by the user. This is very useful, because it allows you to create a set of policies, and then attach them to a group. All users that are members of that group will automatically get those policies. This is a very powerful feature, and it allows you to create a set of policies, and then apply them to a large number of users, without having to attach the policies to each user individually.

## Groups
Groups are collections of users. Users can be members of multiple groups. Groups can have policies attached to them. When a user is a member of a group, the policies attached to the group are inherited by the user. This is very useful, because it allows you to create a set of policies, and then attach them to a group. All users that are members of that group will automatically get those policies. This is a very powerful feature, and it allows you to create a set of policies, and then apply them to a large number of users, without having to attach the policies to each user individually.

## Policies
Policies are the main way to control access to AWS. There are two types of policies: managed policies, and inline policies. Managed policies are policies that are created by AWS, and they are available to all AWS accounts. Managed policies are global, and they cannot be modified. Inline policies are policies that are created by the account owner, and they can be modified. Inline policies are account-specific, and they can be attached to users, groups, and roles.

Policies can be resource based, or they can be identity based. Resource based policies define what actions can be performed on which resources. Identity based policies define what actions can be performed by which identities. For example, you can create a policy that allows a user to read objects from an S3 bucket. You can also create a policy that allows a user to read objects from an S3 bucket, but only if the user is a member of a specific group. This is a very powerful feature, and it allows you to create a set of policies, and then apply them to a large number of users, without having to attach the policies to each user individually.

### Policy syntax
Policies are written in JSON. The syntax is very simple, and it is easy to understand. Here is an example of a policy that allows a user to read objects from an S3 bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket/*"
      ]
    }
  ]
}
```
- `Version` is the version of the policy syntax. This is a required field.
- `Statement` is an array of statements. A statement is a single rule that defines what actions can be performed on which resources. This is a required field.
- `Sid` is a statement ID. This is an optional field.
- `Effect` is the effect of the statement. It can be `Allow` or `Deny`. This is a required field.
- `Action` is an array of actions that are allowed or denied. This is a required field.
- `Resource` is an array of resources that the actions can be performed on. This is a required field.
- `Principal` is an array of identities that the actions can be performed by. This is an optional field.
- `Condition` is a set of conditions that must be met for the statement to be true. This is an optional field.
- `NotPrincipal` is an array of identities that the actions cannot be performed by. This is an optional field.
- `NotAction` is an array of actions that are not allowed. This is an optional field.
- `NotResource` is an array of resources that the actions cannot be performed on. This is an optional field.
- `NotCondition` is a set of conditions that must not be met for the statement to be true. This is an optional field.

Reference for the policy syntax can be found [here](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html).

## Roles
Roles are a way to delegate access to other AWS services. Roles can be assumed by users, services, or applications. Roles can be attached to users, groups, or services. When a user assumes a role, the policies attached to the role are inherited by the user. This is very useful, because it allows you to create a set of policies, and then attach them to a role. All users that assume that role will automatically get those policies. This is a very powerful feature, and it allows you to create a set of policies, and then apply them to a large number of users, without having to attach the policies to each user individually.
