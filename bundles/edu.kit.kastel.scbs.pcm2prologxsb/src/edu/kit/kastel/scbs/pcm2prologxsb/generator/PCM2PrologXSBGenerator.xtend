package edu.kit.kastel.scbs.pcm2prologxsb.generator

import edu.kit.ipd.sdq.mdsd.ecore2log.config.UserConfiguration
import edu.kit.ipd.sdq.mdsd.ecore2log.generator.AbstractProfiledEcore2LogGenerator
import edu.kit.kastel.scbs.confidentiality.repository.ParametersAndDataPair
import edu.kit.kastel.scbs.pcm2prologxsb.config.PCM2PrologXSBFilter
import edu.kit.kastel.scbs.pcm2prologxsb.config.PCMNameConfiguration
import edu.kit.kastel.scbs.pcm2prologxsb.config.PrologXSBLogConfiguration
import java.util.ArrayList
import java.util.Collections
import java.util.Comparator
import java.util.List
import org.eclipse.core.resources.IFile
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.modelversioning.emfprofileapplication.StereotypeApplication
import org.palladiosimulator.pcm.repository.OperationInterface
import org.palladiosimulator.pcm.repository.Parameter

class PCM2PrologXSBGenerator extends AbstractProfiledEcore2LogGenerator<PCMNameConfiguration> {
	private val SpecificationParameterRemover specificationParameterRemover = new SpecificationParameterRemover()
	
	new(UserConfiguration userConfiguration) {
		super(new PCM2PrologXSBFilter, new PCMNameConfiguration, new PrologXSBLogConfiguration, userConfiguration)
	}
	
	override getFolderNameForResource(Resource inputResource) {
		return "src-gen"
	}
	
	override getFileNameForResource(Resource inputResource) {
		return nameConfig.getFileName(inputResource) + "." + nameConfig.getFileExtension
	}
	
	override preprocessInputFiles(List<IFile> inputFiles) {
		return sortInputFiles(inputFiles)
	}
	
	override String generateAttributeValue(EObject e, Object attributeValue) {
		if (attributeValue === null) return logConfig.generateNullPlaceholder();
		val valString = attributeValue.toString();
		try {
			Integer.parseInt(valString)
			return valString
		} catch (NumberFormatException nfe) {
			if (nameConfig.isKeyword(valString)) {
				return valString
			} else {
				return "\"" + valString.replace("\"","\\\"") + "\""
			}
		}
		        
	}
	
//	override preprocessInputResourceInPlace(Resource inputResource) {
//		inputResource.allContents.forEach[preprocessContent(it)]
//	}
	
//	private def dispatch void preprocessContent(EObject eObject) {
//		// nothing to do in general
//	}
//	
//	private def dispatch void preprocessContent(AssemblyContext ac) {
//		this.specificationParameterRemover.preprocessSpecificationParameterEquationsAtAssemblyContext(ac)
//	}
	
	private def List<IFile> sortInputFiles(List<IFile> inputFiles) {
		val preprocessedInputFiles = new ArrayList(inputFiles.size)
		preprocessedInputFiles.addAll(inputFiles)	
		Collections.sort(preprocessedInputFiles, new Comparator<IFile>() {
			override compare(IFile o1, IFile o2) {
				val fileExtIndex1 = fileExt2Index(o1.fileExtension)
				val fileExtIndex2 = fileExt2Index(o2.fileExtension)
				return fileExtIndex1.compareTo(fileExtIndex2)
			}
			
			def private int fileExt2Index(String fileExt) {
				switch fileExt {
					case 'confidentiality' : 0
					case 'adversary' : 1
					case 'repository' : 2
					case 'system' : 3
					case 'resourceenvironment' : 4
					case 'allocation' : 5
					default : 6
				}
			}
		})
		return preprocessedInputFiles
	}
	
	def dispatch String generateSingleFeatureValue(ParametersAndDataPair p, EAttribute attribute, String referencedString) {
		if (nameConfig.isReturnParameter(referencedString)) return nameConfig.returnAtom
		if (nameConfig.isCallParameter(referencedString))   return nameConfig.callAtom
		if (nameConfig.isWildCard(referencedString))        return nameConfig.wildCardAtom

		if (nameConfig.isParameterSourcesAttribute(attribute) && nameConfig.isSizeOfParameter(referencedString)) {
			val parameterName = nameConfig.getParameterNameFromSizeOf(referencedString)
			if (nameConfig.isWildCard(parameterName)) {
				return "sizeOf(" + nameConfig.wildCardAtom + ")"
			} else {
				return "sizeOf(" + getParameterId(parameterName) + ")"
			}
		}
		super.generateSingleFeatureValue(p, attribute, referencedString)
	}
	
	override String generateMainContent(EList<EObject> firstLevelContents) {
//		specificationParameterRemover.preProcessFirstLevelContentsToBuildUpMaps(firstLevelContents)
		return super.generateMainContent(firstLevelContents)
	}
	
	override generateDeeply(EObject e) {
		return generateDeeplyCorrectly(e)
	}
	
	def dispatch String generateDeeplyCorrectly(EObject e) {
		return super.generateDeeply(e)
	}
	
	def dispatch String generateDeeplyCorrectly(Parameter p) {
		val parameterPredicate = super.generateDeeply(p)
		val sizeOfId = getSizeOfId(p.parameterName)
		val predicateName = "sizeOf" + nameConfig.getInstanceName(p).toFirstUpper
		val sizeOfParameterPredicate = generatePredicate(predicateName, sizeOfId)
		val relationName = "sizeOf"
		val value = generateID(p)
		val sizeOfRelation = generateRelation(relationName, sizeOfId, value)
		return parameterPredicate + sizeOfParameterPredicate + sizeOfRelation
	}
	
	def dispatch String generateDeeplyCorrectly(StereotypeApplication sa) {
		val stereotypeName = sa?.stereotype?.name
		val informationFlowStereotypeName = "InformationFlow"
		if (stereotypeName?.equals(informationFlowStereotypeName) && sa.appliedTo instanceof OperationInterface) {
			var instanceCommentOpening = ""
			var instanceCommentClosing = ""
			var newLine = ""
			if (userConfig.generateComments) {
				instanceCommentOpening = generateInstanceCommentOpening(sa)
				instanceCommentClosing = generateInstanceCommentClosing(sa)
				newLine = generateNewLine()
			}
			val content = generateInformationFlowForAllSignatures(sa)
			return newLine + instanceCommentOpening + content + instanceCommentClosing + newLine
		}
		return super.generateDeeply(sa)
	}
	
	private def String generateInformationFlowForAllSignatures(StereotypeApplication sa) {
		val padpFeatureName = "parametersAndDataPairs"
		val padpFeature = sa.eClass.getEStructuralFeature(padpFeatureName)
		val featureValue = generateFeatureValues(sa, padpFeature)
		var content = ""
		val iface = sa.appliedTo as OperationInterface
		for (signature : iface.signatures__OperationInterface) {
			val signatureID = generateID(signature)
			// FIXME MK use generatePredicate or generateRelation
			content += padpFeatureName + logConfig.generatePredicateOpening + signatureID + logConfig.generatePredicateSeparator + featureValue + logConfig.generatePredicateClosing
		}
		return content
	}
	
//	def dispatch String generateDeeplyCorrectly(AssemblyConnector ac) {
//		specificationParameterRemover.prepareInformationFlowSpecificationsForParameterAssignments(ac)
//		val assignmentReplacements = generateInformationFlowForAssignments(ac)
//		return super.generateDeeply(ac) + assignmentReplacements
//	}
	
//	override generateFeatureValues(EObject e, EStructuralFeature feature) {
//		return generateFeatureValuesCorrectly(e, feature)
//	}
	
//	def dispatch List<String> generateFeatureValuesCorrectly(EObject e, EStructuralFeature feature) {
//		return super.generateFeatureValues(e, feature)
//	}
		
//	def dispatch List<String> generateFeatureValuesCorrectly(ParametersAndDataPair padsp, EReference reference) {
//		// only generate relations for those dataTargets that are not parameterized
//		// i.e. skip all parameterized dataTargets
//		val dataTargetsName = "dataTargets"
//		if (reference.name?.equals(dataTargetsName)) {
//			val dataTargets = padsp.eGet(reference) as List<DataIdentifying>
//			val unparameterizedDataTargets = new BasicEList<DataIdentifying>(dataTargets.size)
//			for (dataTarget : dataTargets) {
//				if (dataTarget instanceof UnparameterizedDataIdentifying) {
//					unparameterizedDataTargets.add(dataTarget)
//				}
//			}
//			return generateManyFeatureValues(padsp,reference,unparameterizedDataTargets)
//		}
//		return super.generateFeatureValues(padsp,reference)
//	}
	
	private def String getSizeOfId(String parameterName) {
		var sizeOfId = "sizeOf_" + parameterName + "_"
		if (userConfig.simplifyIDs) {
			sizeOfId = nameConfig.getSimpleIDValue(sizeOfId)?.toString
		}
		return sizeOfId
	}
	
	private def String getParameterId(String parameterName) {
		var parameterId = parameterName
		if (userConfig.simplifyIDs) {
			parameterId = nameConfig.getSimpleIDValue(parameterName)?.toString
		}
		return parameterId
	}
	
//	/** CAUTION SIDE-EFFECTS: if unassignedSpecificationParameters or dataSetMapEntriesWithUnassignedParameters are provided, they are changed!
//	 * 
//	 *@param unassignedSpecificationParameters optional
//	 */
//	private def String generateInformationFlowForAssignments(Connector connector) {
//		val roleSpecificRelationName = "connectorSpecificParametersAndDataPairs"
//		val parametersAndDataPairName = "parametersAndDataPair"
//			
//		var contents = ""
//		val aSDSMEs = specificationParameterRemover.assignmentSpecificDataSetMapEntries
//		var instanceCommentOpening = ""
//		var instanceCommentClosing = ""
//		var newLine = ""
//		if (userConfig.generateComments) {
////			instanceCommentOpening = generateInstanceCommentOpening(assignment)
////			instanceCommentClosing = generateInstanceCommentClosing(assignment)
//			newLine = generateNewLine()
//		}
//		contents += generateAssignmentSpecificEntries(aSDSMEs)
//		// we map dataIdentifiers for each connector in order to avoid re-generating them several times
//		val aSPADPMap = specificationParameterRemover.assignmentSpecificParametersAndDataPairs
//		val connectorID = generateID(connector)
//		val aSPADPs = aSPADPMap.get(connector)
//		if (aSPADPs != null) {
//			val idsOfNewPairs = new ArrayList<String>()
//			for (aSPADP : aSPADPs) {
//				val parametersAndDataPair = aSPADP.first
//				val currentDataTarget= aSPADP.second
//				val replacementDataIdentifying = aSPADP.third
//				val replacement = switch (replacementDataIdentifying) {
//					DataSetMapEntry : "[" + generateID(replacementDataIdentifying) + "]"
//					DataSet : replacementDataIdentifying.name
//				}		
//				if (replacement != null) {
//					// we will now generate special parametersAndDataPairs relations
//					// which are only concerning the provided role of the connector
//					val idOfNewPair = generateIDValue(parametersAndDataPair, generateID(parametersAndDataPair) + "_" + generateID(connector) + "_substitute_" + currentDataTarget.parameter.name + "_in_" + currentDataTarget.map.name)// + "_with_" + replacement)
//					idsOfNewPairs.add(idOfNewPair)
//					// FIXME MK use generatePredicate or generateRelation
//					val instanceContent = parametersAndDataPairName + logConfig.generatePredicateOpening + idOfNewPair + logConfig.generatePredicateClosing
//					val sourcesFeatureName = "parameterSources"
//					val sourcesFeature = parametersAndDataPair.eClass.getEStructuralFeature(sourcesFeatureName)
//					//val sourcesValue = generateSingleFeatureValue(parametersAndDataPair, sourcesFeature)
//					val sourcesValue = generateManyFeatureValues(parametersAndDataPair,sourcesFeature)
//					val sourcesContent = generateRelation(sourcesFeatureName, idOfNewPair, concatAndFilterFeatureValue(sourcesValue))
//					val targetsFeatureName = "dataTargets"
//					// do the actual assignment by using the replacement instead of the data target value
//					val targetsValue = replacement
//					val targetsContent = generateRelation(targetsFeatureName, idOfNewPair, targetsValue)
//					contents += newLine + instanceCommentOpening + instanceContent + newLine + sourcesContent + newLine + targetsContent + instanceCommentClosing + newLine
//					contents += newLine + generateRelation("originalParametersAndDataPair", idOfNewPair, generateID(parametersAndDataPair)) + newLine
//				}
//			}
//			if (idsOfNewPairs.size > 0) {
//				val roleValue = idsOfNewPairs.toString
//				val roleContent = generateRelation(roleSpecificRelationName, connectorID, roleValue)
//				contents += newLine + instanceCommentOpening + roleContent + instanceCommentClosing + newLine
//			}
//		}
//		return contents
//	}
//	
//	private def generateAssignmentSpecificEntries(Collection<Pair<ConfidentialitySpecification, DataSetMapEntry>> aSDSMEs) {
//		var contents = ""
//		for (aSDSME : aSDSMEs) {
//			val confidentialitySpecification = aSDSME.key
//			val dataSetMapEntry = aSDSME.value
//			contents += generateInstancePredicate(dataSetMapEntry)
//			val relationName = "dataIdentifier"
//			contents += generateRelation(relationName, generateID(confidentialitySpecification), generateID(dataSetMapEntry))
//		}
//		return contents
//	}
}