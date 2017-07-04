# PCM2Prolog
Generate Prolog code for Palladio software architecture models

Generate Prolog code for analysing the confidentiality of data flows in architecture models that were created using the [Palladio Component Model (PCM)](http://palladio-simulator.com/).

See also [PCM2Java4Key](https://github.com/KASTEL-SCBS/PCM2Java4Key) for generating Java code to be verified using KeY from such architecture models using a subset of the confidentiality specification for architectural analysis.

## Development
Currently, the only way to install PCM2Prolog is to compile its Eclipse plug-ins in the same way as if you would change or extend the implementation (an Eclipse-update site will follow). The set up involves three steps in which you prepare an Eclipse IDE, import the plug-in code, and run a new Eclipse that has the plug-ins installed.
### Prepare Development Eclipse
If you already have set up an Eclipse for [PCM2Java4Key](https://github.com/KASTEL-SCBS/PCM2Java4Key), then you can directly reuse and skip the following preparation, but we recommend to create a new empty workspace for PCM2Prolog.
* Download and run a clean [**Neon2** Release of the **Eclipse** IDE for Java and **DSL Developers*](https://www.eclipse.org/downloads/packages/eclipse-ide-java-and-dsl-developers/neon2). Do not use another Eclipse Package, i.e. also not the one for Java developers.
* Install Eclipse **OCL 6.0.1** using the Eclipse Marketplace
  * Help - Eclipse Marketplace ... - Search for "OCL"
* Install **Palladio 4.0** from the [Palladio Simulator nightly builds site](https://sdqweb.ipd.kit.edu/eclipse/palladiosimulator/nightly/)
  * Help - Install New Software... - Add...
  * Select at least **all "Palladio Bench Core Features"** and the **"MDSD Profiles"** feature of the "Palladio Supporting Features" category 
* Install EMF Profiles from the [update site](http://www.modelversioning.org/emf-profiles-updatesite/)
  * Help - Install New Software... - Add...
  * (This step is necessary because the feature "MDSD Profiles" of Palladio only depends on those features of EMF Profiles that are necessary to use existing and pre-installed profiles but not the features that are needed to create, modify and use new profiles.)

### Clone Repository and Import Projects
* Clone the [PCM2Prolog repository](https://github.com/KASTEL-SCBS/PCM2Prolog) **and its submodules** and import all Eclipse plug-in projects (aka bundles) in it into your workspace
  * both can be done at once in Eclipse
    * right-click in the Package Explorer - Import - Git - Projects from Git - Clone URI
    * make sure you check the box "Clone submodules" in the wizard
    * as you do not need to import the feature projects you can either set the scope of the wizard to the folder "bundles" in the "Working Tree" or you deselect these projects from the list (but importing the feature projects too will not do any harm)

### Run new Eclipse with Confidentiality Specification and Architectural Analysis Support
* Run Palladio with the possibility to specifcy confidentiality for architectural analysis
  * run a new "Eclipse Application" that is started from the Eclipse in which you checked out all plug-in projects as specified above
  * this can be done e.g. by creating a new debug configuration for an "Eclipse Application" with default settings).
    * Run - Debug Configurations - Eclipse Configuration - right click - New
* Create or modify a new or existing Palladio model in the workspace of the new Eclipse
  * e.g. import an existing project ("Import - Existing Projects into Workspace")
  * e.g. clone and import an example from the [Examples Repository](https://github.com/KASTEL-SCBS/Examples4SCBS)
  * e.g. right-click - New - Other - Palladio Modeling - New Palladio Project

## Usage
### Create Architecture Model, Confidentiality Specification, and Adversary Model in Eclipse
* To model the component repository, system assembly, resource environment, and allocation you can use the wizard and graphical or tree-based editors of Palladio
  * e.g. using "New - Palladio Modeling - PCM ... Diagram"
* To create a confidentiality specification model you can use the wizard and tree-based editor
  * New - Other - Example EMF Model Creation Wizards - Confidentiality Model (keep "Specification" as "Model Object")
* To use the confidentiality specification in Palladio models you have to use the tree-based editor
  * open the tree-based editor by opening, for example, a .repository file with a double-click or right-click "Open with - Repository Model Editor"
  * right-click on the root element of a Palladio model (i.e. a "Repository", "System", "Resource Environment", or "Allocation" element)
  * Select "MDSD Profiles - Apply/Unapply Profiles" and add "Profile PCMConfidentialityProfile" in the dialog
  * Select the model element to which a confidentiality specification shall be added, right-click "MDSD Profiles - Apply/Unapply Stereotypes" and add the appropriate stereotype
* To create an adversary model you can use the wizard and tree-based editor
  * New - Other - Example EMF Model Creation Wizards - Adversary Model, then choose "Adversaries" as "Model Object"
  
### Generate Prolog XSB Code for the Architectural Confidentiality Analysis
* Select an allocation, repository, resource environment, **and** system model (e.g. while pressing Ctrl)
* Right-click somewhere on the selection - KASTEL Architecture Analysis - Create Prolog XSB Code

### Run the Prolog-based Architectural Confidentiality Analysis
* <code>make all.P</code>
* <code>make queries-justify.result</code>
* <code>make queries.result</code>
