---
layout: slide
title: Slides for a git and GitHub workshop
date: 2022-05-10 02:30
author: Raimund Rittnauer
description: Some slides for a git and GitHub workshop using reveal.js
categories: education
comments: true
tags:
  - education
  - workshop
  - slides
---

<section data-markdown>
    <textarea data-template>
        # git
        /ɡɪt/
        ---
        <img src="/assets/img/2022-05-11-git-github-workshop/git-logo.png" />
        ---
        ## What does Wikipedia say?
        - Git is a software for __tracking changes__ in any set of files, usually used for __coordinating work among programmers__ collaboratively developing source code during software development.
        - Its goals include speed, data integrity, and support for distributed, non-linear workflows (thousands of parallel branches running on different systems).
        ---
        ## Development of git
        - Git was originally authored by Linus Torvalds in 2005 for development of the Linux kernel, with other kernel developers contributing to its initial development.
        - Distributed version control system
        - [https://git-scm.com/](https://git-scm.com/)
        ---
        <img src="/assets/img/2022-05-11-git-github-workshop/torvalds.png">
        <br />
        Linus Torvalds
        ---
        ## Distributed Version Control System
        - is a form of version control in which the complete codebase, including its full history, is mirrored on every developer's computer.
        - Compared to centralized version control
           - automatic management branching and merging
           - speeds up most operations
           - ability to work offline
           - does not rely on a single location for backups
        ---
        ## Centralized vs Distributed
        <img src="/assets/img/2022-05-11-git-github-workshop/centralized-distributed.png">
        ---
        ## git in a nutshell
        - Tracks code changes
        - Tracks who made changes
        - Enables coding collaboration
        ---
        ## But why git?
        - Developers can work together from anywhere in the world.
        - Developers can see the full history of the project.
        - Developers can revert to earlier versions of a project.
        ---
        <img src="/assets/img/2022-05-11-git-github-workshop/github-logo.png">
        ---
        ## GitHub
        - Offers the distributed version control and source code management (SCM) functionality of Git
        - Provider of Internet hosting for software development and version control using Git
        - [https://github.com/](https://github.com/)
        ---
        <img src="/assets/img/2022-05-11-git-github-workshop/gitlab-logo.png">
        ---
        ## GitLab
        - DevOps software that combines the ability to develop, secure, and operate software in a single application.
        - It was a source code management solution to collaborate within a team on software development that evolved to an integrated solution covering the software development life cycle, and then to the whole DevOps life cycle.
        - Free and open-source
        - [https://gitlab.com/](https://gitlab.com/)
        ---
        ## git != GitHub != GitLab
        ---
        ## git
        let's get started
        ---
        ## git vocabularies
        - Repository
        - Clone
        - Add
        - Status
        - Commit
        - Pull
        - Push
        - Branch
        - Merge
        ---
        <!-- .slide: data-background-image="/assets/img/2022-05-11-git-github-workshop/mangotime1.jpg" -->
        ## ~~Mango~~Demotime
        ---
        ## git vocabularies
        - __Repository__
        - Clone
        - Add
        - Status
        - Commit
        - Pull
        - Push
        - Branch
        - Merge
        ---
        ## Repository
        - Rough explanation: contains all your data (source code files) and their versions (history)
        - Remote repository -> on the server
        - Local repository -> on the client
        ---
        ## git vocabularies
        - Repository
        - __Clone__
        - Add
        - Status
        - Commit
        - Pull
        - Push
        - Branch
        - Merge
        ---
        ## git clone
        - Clones (creates a copy) a repository from the server to the client (laptop, desktop computer, smartphone, …)
        ```bash
        git clone https://github.com/raaaimund/hello-world.git 
        ```
        ---
        ## git vocabularies
        - Repository
        - Clone
        - __Add__
        - Status
        - Commit
        - Pull
        - Push
        - Branch
        - Merge
        ---
        ## git add
        - Makes (changed/added/removed) files ready to commit

        Add all files of the current directory
        ```bash
        git add .
        ```

        Add a specific file
        ```
        git add Main.java
        ```
        ---
        ## git vocabularies
        - Repository
        - Clone
        - Add
        - __Status__
        - Commit
        - Pull
        - Push
        - Branch
        - Merge
        ---
        ## git status
        - If you are not sure what’s the current status -> check the status
        ```bash
        git status
        ```
        <img src="/assets/img/2022-05-11-git-github-workshop/git-status.png">
        ---
        ## git vocabularies
        - Repository
        - Clone
        - Add
        - Status
        - __Commit__
        - Pull
        - Push
        - Branch
        - Merge
        ---
        ## git commit
        - Makes (changed/added/removed) files ready on the local repository to push to the remote repository.
        - Adds a message to those files for explaining collaborators (your colleagues) what was changed/implemented/fixed
        ```bash
        git commit –m “short and precise commit message”
        ```
        ---
        ## git commit
        - Commit early, commit often, push often
        - Keep your commit messages small and precise
        - Keep your commits small
        - Smaller commits result in less code to review!
        ---
        ## git vocabularies
        - Repository
        - Clone
        - Add
        - Status
        - Commit
        - __Pull__
        - Push
        - Branch
        - Merge
        ---
        ## git pull
        - Pulls (synchronizes) all changes of the current branch from the remote repository to the local repository
        ```bash
        git pull
        ```
        ---
        ## git vocabularies
        - Repository
        - Clone
        - Add
        - Status
        - Commit
        - Pull
        - __Push__
        - Branch
        - Merge
        ---
        ## git push
        - Pushes (synchronizes) all changes of the current branch from the local  repository to the remote repository
        ```bash
        git push
        ```
        ---
        ## git vocabularies
        - Repository
        - Clone
        - Add
        - Status
        - Commit
        - Pull
        - Push
        - __Branch__
        - __Merge__
        ---
        ## Branching and Merging
        <img src="/assets/img/2022-05-11-git-github-workshop/branches1.png">
        ---
        <!-- .slide: data-background-image="/assets/img/2022-05-11-git-github-workshop/delhi-metro.svg" -->
        ---
        ## git branch
        - List all local branches
        ```bash
        git branch
        ```
        - List all remote branches
        ```bash
        git branch -r
        ```
        - List all branches
        ```bash
        git branch -a
        ```
        ---
        ## git checkout
        - Create a new branch
        ```bash
        git checkout -b "branch name"
        ```
        - Switch to a branch / switch between branches
        ```bash
        git checkout "branch name"
        ```
        ---
        ## git merge
        - Merge one branch into the current branch
        - Switch to the branch into which you want to merge
        ```bash
        git checkout "to-branch"
        ```
        - Merge the branch into the current branch
        ```bash
        git merge "from-branch"
        ```
        ---
        ## git log
        - Shows the branches and their commits
        ```bash
        git log
        ```
        - Show log in graph view
        ```bash
        git log --graph
        ```
        ---
        ## Branching and Merging
        <img src="/assets/img/2022-05-11-git-github-workshop/branches1.png">
        ---
        ## Branching and Merging
        - Create a branch for each feature you want do develop
        - Implement the feature together with your colleagues/collaborators
        - Merge the feature to the main/master branch when finished implementing
        - Often there is also a dev/development branch
        ---
        ## Branching and Merging
        - Never ever (4 real) push directly to the main/master branch.
        - The main/master branch should be a stable version of your software at ALL time after checkout/cloning.
        - Use branches for implementing features.
        ---
        ## You do not want to be a sneaky fox!
        <img class="stretch" src="/assets/img/2022-05-11-git-github-workshop/sneaky-fox.jpg">
        ---
        ## Pull Request / Merge Request
        - Merging on GitHub
        - After your implementation on a branch is finalized -> open a PR (Pull Request)
        - After PR was reviewed, merge the changes to the main/master branch
        ---
        ## GitHub Pages
        Websites for you and your projects
        ---
        ## GitHub Pages
        - Hosted directly from your GitHub repository.
        - Just edit, push, and your changes are live.
        - [https://pages.github.com/en](https://pages.github.com/)
        ---
        ## You just have to
        - Head over to GitHub and create a new public repository named __username.github.io__, where username is your username (or organization name) on GitHub.
        - If the first part of the repository doesn’t exactly match your username, it won’t work, so make sure to get it right.
        ---
        <img class="stretch" src="/assets/img/2022-05-11-git-github-workshop/create-githubpages-project.png">
        ---
        <!-- .slide: data-background-image="/assets/img/2022-05-11-git-github-workshop/mangotime2.jpg" -->
        ## ~~Mango~~Demotime
        ---
        ## Spck Code Editor
        Use HTML, CSS, JavaScript, and git on your Android phone
        ---
        ## Spck Code Editor
        - [https://play.google.com/store/apps/details?id=io.spck](https://play.google.com/store/apps/details?id=io.spck)
        - [https://spck.io/](https://spck.io/)
        ---
        <!-- .slide: data-background-image="/assets/img/2022-05-11-git-github-workshop/mangotime3.jpg" -->
        ## ~~Mango~~Demotime
        ---
        ## Other IDEs
        - You can also use other IDEs
           - Visual Studio Code
           - WebStorm
           - Atom
           - …
        ---
        ## Now it’s your turn
        - Go to [https://github.com/](https://github.com/)
        - Create an account
        - Create a public repository for GitHub pages (username.github.io)
        - Continue solo or team up with others (maximum 3 people per team)
           - Invite your team members as collaborators (Settings -> Collaborators)
        - Create a website about you/your hobby/a project/a movie/a blog/a diary/…
        - Check it out on [https://username.github.io/](https://username.github.io/)
        ---
        ## Need some inspiration?
        - Here is my website -> [https://raaaimund.github.io/](https://raaaimund.github.io/)
        - Other awesome student projects -> [https://education.github.com/pack/gallery](https://education.github.com/pack/gallery)
        ---
        ## CI/CD
        Continuous Integration / Continous Delivery / Continuous Deployment
        ---
        ## CI/CD
        - CI/CD is a method to frequently deliver apps to customers by introducing automation into the stages of app development.
        - The main concepts attributed to CI/CD are continuous integration, continuous delivery, and continuous deployment.
        - CI/CD is a solution to the problems integrating new code can cause for development and operations teams.
        ---
        ## CI
        - Successful CI means new code changes to an app are regularly built, tested, and merged to a shared repository.
        - It’s a solution to the problem of having too many branches of an app in development at once that might conflict with each other.
        ---
        ## CD
        - Continuous delivery usually means a developer’s changes to an application are automatically bug tested and uploaded to a repository (like GitHub or a container registry), where they can then be deployed to a live production environment by the operations team.
        - The purpose of continuous delivery is to ensure that it takes minimal effort to deploy new code.
        ---
        ## CD
        - Continuous deployment (the other possible "CD") can refer to automatically releasing a developer’s changes from the repository to production, where it is usable by customers.
        - It addresses the problem of overloading operations teams with manual processes that slow down app delivery. It builds on the benefits of continuous delivery by automating the next stage in the pipeline.
        ---
        ## CI/CD
        <img src="/assets/img/2022-05-11-git-github-workshop/ci-cd.jpg">
        ---
        ## GitHub Workflows
        - A workflow is a configurable automated process that will run one or more jobs.
        - Workflows are defined by a YAML file checked in to your repository and will run when triggered by an event in your repository, or they can be triggered manually, or at a defined schedule.
        ---
        ## CI/CD - this blog
        [github.com/raaaimund/raaaimund.github.io/actions](https://github.com/raaaimund/raaaimund.github.io/actions)
        ---
        ## CI/CD - Android application
        [github.com/raaaimund/iwmad22/actions](https://github.com/raaaimund/iwmad22/actions)
        ---
        <!-- .slide: data-background-image="/assets/img/2022-05-11-git-github-workshop/mangotime4.jpg" -->
        ## Avoid the ~~Mango~~Banana-Principle
        ---
        <!-- .slide: data-background-image="/assets/img/2022-05-11-git-github-workshop/mangotime5.jpg" -->
        ## ~~Mango~~Demotime
        ---
        ## Short git recap
        - Repository
        - Clone
        - Add
        - Status
        - Commit
        - Pull
        - Push
        - Branch
        - Merge
        ---
        ## Continue your git/GitHub journey
        - [https://lab.github.com/](https://lab.github.com/)
        - [https://github.com/microsoft/workshop-library](https://github.com/microsoft/workshop-library)
        - [https://education.github.com/git-cheat-sheet-education.pdf](https://education.github.com/git-cheat-sheet-education.pdf)
        - [https://education.github.com/](https://education.github.com/)
        ---
        ## Apply for a student developer pack
        [Apply here](https://docs.github.com/en/education/explore-the-benefits-of-teaching-and-learning-with-github-education/use-github-for-your-schoolwork/apply-for-a-student-developer-pack)
        ---
        ## Credits
        - Images of branching and merging from https://digitalvarys.com/git-branch-and-its-operations/
        - Image of Delhi metro rail map from Government of India
        - CI/CD from [redhat.com](https://redhat.com)
        - [https://www.w3schools.com/git/default.asp?remote=github](https://www.w3schools.com/git/default.asp?remote=github)
        - Microsoft and GitHub for their educational support of students
        ---
        ## Slides
        are available on [rittnauer.at](http://rittnauer.at)
    </textarea>
</section>
