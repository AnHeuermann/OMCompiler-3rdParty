# Working with the OpenModelica/OMCompiler/3rdParty submodule

See also: [OpenModelica/CONTRIBUTING.md](https://github.com/OpenModelica/OpenModelica/blob/master/CONTRIBUTING.md)

If you need to make changes to OMCompiler-3rdParty the procedure is as follows:

* push to a branch in OMCompiler-3rdParty (ask us for access via OpenModelica mailing list)
* make a PR to OpenModelica glue project with OpenModelica/OMCompiler/3rdParty submodule pointing at your commit from the pushed branch in OMCompiler-3rdParty

After Jenkins checks that all is OK a developer will:

* **reset** (or restart, or **merge**, if there were other commits added to OMCompiler-3rdParty since you started) the OMCompiler-3rdParty master branch so the new HEAD contains the HEAD commit of the branch
* merge the PR in the OpenModelica glue project
* delete the branch in the OMCompiler-3rdParty
