package edu.kit.kastel.scbs.pcm2prologxsb.generator

import edu.kit.ipd.sdq.mdsd.ecore2log.config.UserConfiguration
import edu.kit.ipd.sdq.mdsd.ecore2log.generator.AbstractProfiledEcore2LogGenerator
import edu.kit.kastel.scbs.confidentiality.data.DataIdentifying
import edu.kit.kastel.scbs.confidentiality.data.SpecificationParameter
import edu.kit.kastel.scbs.confidentiality.data.DataSet
import edu.kit.kastel.scbs.confidentiality.data.DataSetMap
import edu.kit.kastel.scbs.confidentiality.data.DataSetMapEntry
import edu.kit.kastel.scbs.confidentiality.data.ParameterizedDataSetMapEntry
import edu.kit.kastel.scbs.confidentiality.data.UnparameterizedDataIdentifying
import edu.kit.kastel.scbs.confidentiality.data.impl.DataFactoryImpl
import edu.kit.kastel.scbs.confidentiality.repository.ParametersAndDataPair
import edu.kit.kastel.scbs.confidentiality.system.AbstractSpecificationParameterAssignment
import edu.kit.kastel.scbs.confidentiality.system.SpecificationParameter2DataSetAssignment
import edu.kit.kastel.scbs.confidentiality.system.DataSetMapParameter2KeyAssignment
import edu.kit.kastel.scbs.confidentiality.system.SystemFactory
import edu.kit.kastel.scbs.pcm2prologxsb.config.PCM2PrologXSBFilter
import edu.kit.kastel.scbs.pcm2prologxsb.config.PCMNameConfiguration
import edu.kit.kastel.scbs.pcm2prologxsb.config.PrologXSBLogConfiguration
import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.Comparator
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.core.resources.IFile
import org.eclipse.emf.common.util.BasicEList
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.ecore.resource.Resource
import org.modelversioning.emfprofileapplication.StereotypeApplication
import org.palladiosimulator.pcm.core.composition.AssemblyConnector
import org.palladiosimulator.pcm.core.composition.Connector
import org.palladiosimulator.pcm.repository.OperationInterface
import org.palladiosimulator.pcm.repository.Parameter

import static extension edu.kit.ipd.sdq.commons.util.org.eclipse.emf.ecore.EObjectUtil.*
import static extension edu.kit.ipd.sdq.commons.util.org.palladiosimulator.mdsdprofiles.api.StereotypeAPIUtil.*
import edu.kit.kastel.scbs.confidentiality.ConfidentialitySpecification

class PCM2PrologXSBGenerator extends AbstractProfiledEcore2LogGenerator<PCMNameConfiguration> {
	// FIXME MK replace all three maps with org.apache.commons.collections4.SetValuedMap
	private var Map<SpecificationParameter, Set<String>> dataParam2KeyMap = newHashMap()
	private var Map<DataSetMap, Set<SpecificationParameter>> dataSetMap2ParamMap = newHashMap()
	private var Map<DataSetMap, Set<String>> dataSetMap2Keys = newHashMap()
	private var Map<DataSetMap, Map<String,DataSetMapEntry>> dataSetMapAndKey2Entry = newHashMap()
	
	private var Collection<DataSet> dataSets = new HashSet()
	
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
		if (nameConfig.isParameterSourcesAttribute(attribute) && nameConfig.isSizeOfParameter(referencedString)) {
			val parameterName = nameConfig.getParameterNameFromSizeOf(referencedString)
			return getSizeOfId(parameterName)
		}
		super.generateSingleFeatureValue(p, attribute, referencedString)
	}
	
	override String generateMainContent(EList<EObject> firstLevelContents) {
		preProcessFirstLevelContentsToBuildUpMaps(firstLevelContents)
		return super.generateMainContent(firstLevelContents)
	}
	
	def private void preProcessFirstLevelContentsToBuildUpMaps(EList<EObject> firstLevelContents) {
		for (firstLevelContent : firstLevelContents) {
			preProcessContentToBuildUpMaps(firstLevelContent)
			for (nestedContent : firstLevelContent.getAllContents) {
				preProcessContentToBuildUpMaps(nestedContent)
			}
		}
	}
	
	def private dispatch void preProcessContentToBuildUpMaps(EObject eObject) {
		// do nothing
	}
	
	def private dispatch void preProcessContentToBuildUpMaps(Connector connector) {
		val assignments = getAssignmentsAtConnector(connector)
		for (assignment : assignments) {
			if (assignment instanceof DataSetMapParameter2KeyAssignment) {
				val dsmp2ks = assignment as DataSetMapParameter2KeyAssignment 
				val replacementValue = dsmp2ks.assignedKey
				for (replacedParamKey : dsmp2ks.specificationParametersToReplace) {
					addToSetValuedMap(this.dataParam2KeyMap, replacedParamKey, replacementValue)
				}
			}
		}
		// FIXME MK support unassigned parameters at interfaces that are used for connectors in composite components (not only for connectors in systems)
	}
	
	// TODO MK this is obsolete as soon as the first three maps are replaced with org.apache.commons.collections4.SetValuedMap
	def static private <K,V> void addToSetValuedMap(Map<K,Set<V>> map, K key, V value) {
		var valueSet = map.get(key)
		if (valueSet == null) {
			valueSet = new HashSet<V>()
			map.put(key, valueSet)
		}
		valueSet.add(value)
	}
	
	// TODO MK this is obsolete as soon as the first three maps are replaced with org.apache.commons.collections4.SetValuedMap
	def static private <K,V> Set<V> getFromSetValuedMap(Map<K,Set<V>> map, K key) {
		var Set<V> values = map.get(key)
		if (values == null) {
			values = newHashSet()
		}
		return values
	}
	
	// TODO MK this is obsolete as soon as the fourth map is replaced with org.apache.commons.collections4.?
	def static private <K,L,V> void addToMapValuedMap(Map<K,Map<L,V>> firstMap, K firstKey, L secondKey, V value) {
		var secondMap = firstMap.get(firstKey)
		if (secondMap == null) {
			secondMap = newHashMap()
			firstMap.put(firstKey, secondMap)
		}
		secondMap.put(secondKey, value)
	}

	// TODO MK this is obsolete as soon as the fourth map is replaced with org.apache.commons.collections4.?
	def static private <K,L,V> V getFromMapValuedMap(Map<K,Map<L,V>> firstMap, K firstKey, L secondKey) {
		val secondMap = firstMap.get(firstKey)
		return secondMap?.get(secondKey)
	}
		
	def private dispatch void preProcessContentToBuildUpMaps(DataSetMapEntry dsme) {
		val mapKey = dsme.map
		val keyOrIndexValue = dsme.name
		addToSetValuedMap(this.dataSetMap2Keys, mapKey, keyOrIndexValue)
		addToMapValuedMap(this.dataSetMapAndKey2Entry, mapKey, keyOrIndexValue, dsme)
	}
	
	def private dispatch void preProcessContentToBuildUpMaps(ParameterizedDataSetMapEntry pdsme) {
		val mapKey = pdsme.map
		val parameterValue = pdsme.parameter
		addToSetValuedMap(this.dataSetMap2ParamMap, mapKey, parameterValue)
	}
	
	def private dispatch void preProcessContentToBuildUpMaps(DataSet dataSet) {
		this.dataSets.add(dataSet)
	}
	
	def private Set<String> getUsedKeysForDataSetMap(DataSetMap dataSetMap) {
		// get directly used keys
		val possibleKeys = getFromSetValuedMap(this.dataSetMap2Keys, dataSetMap)
		// add indirectly used keys
		val usedParameters = this.dataSetMap2ParamMap.get(dataSetMap)
		for (usedParameter : usedParameters) {
			val usedKeys = this.dataParam2KeyMap.get(usedParameter)
			if (usedKeys != null) {
				possibleKeys.addAll(usedKeys)
			}
		}
		return possibleKeys
	}
	
	def private Iterable<DataSet> getUsedDataSets() {
		return this.dataSets
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
	
	// FIXME MK GENERALIZE THIS SO THAT IT ALSO WORKS FOR DELEGATION CONNECTORS
	def dispatch String generateDeeplyCorrectly(AssemblyConnector ac) {
		// at the beginning the variable unassignedSpecificationParameters contains all data parameters (assigned or not)
		val unassignedSpecificationParameters = getSpecificationParametersForProvidedInterfaceOfConnector(ac)
		val dataSetMapEntriesWithUnassignedParameters = getDataSetMapEntriesWithUnassignedParametersForProvidedInterfaceOfConnector(ac)
		var assignmentContent = ""
		if (!unassignedSpecificationParameters.isEmpty) {
			val assignments = getAssignmentsAtConnector(ac)
			// if a parameter is assigned, the effect of the relations that we generate for the assignment
			// is the same as if we would have directly generated the relations for the assigned data sets or
			// data set map entries during the generation of the other relations for the provided interface
			assignmentContent += generateInformationFlowForAssignments(assignments, ac, unassignedSpecificationParameters, dataSetMapEntriesWithUnassignedParameters)
			// now the variable unassignedSpecificationParameters really contains only those data parameters that were not assigned
			// and dataSetMapEntriesWithUnassignedParameters really contains only such entries
			val unassignedSpecificationParameterIterator = unassignedSpecificationParameters.iterator
			while (unassignedSpecificationParameterIterator.hasNext) {
				val unassignedSpecificationParameter = unassignedSpecificationParameterIterator.next
				// if a parameter is not assigned, the effect of the relations that we generate for the missing
				// assignment is the same as if we would have directly generated the relations for _all_ existing data sets and _all_ existing data set map entries during the generation for the interface
				assignmentContent += generateInformationFlowForMissingAssignment(ac, unassignedSpecificationParameter)			
				unassignedSpecificationParameterIterator.remove
			}
			// FIXME MK remove this code duplication of this two while loops by concatenating the iterators using Guava Iterators.concat
			val dataSetMapEntriesWithUnassignedParametersIterator = dataSetMapEntriesWithUnassignedParameters.iterator
			while (dataSetMapEntriesWithUnassignedParametersIterator.hasNext) {
				val dataSetMapEntryWithUnassignedParameter = dataSetMapEntriesWithUnassignedParametersIterator.next
				// if a parameter is not assigned, the effect of the relations that we generate for the missing
				// assignment is the same as if we would have directly generated the relations for _all_ existing data sets and _all_ existing data set map entries during the generation for the interface
				assignmentContent += generateInformationFlowForMissingAssignment(ac, dataSetMapEntryWithUnassignedParameter)			
				dataSetMapEntriesWithUnassignedParametersIterator.remove
			}

			if (!unassignedSpecificationParameters.isEmpty) {
				throw new RuntimeException("The unassigned data parameters '" + unassignedSpecificationParameters + "' were not processed!")
			}
		}
		return super.generateDeeply(ac) + assignmentContent
	}
	
	private def Set<SpecificationParameter> getSpecificationParametersForProvidedInterfaceOfConnector(AssemblyConnector connector) {
		val providedInterface = connector.providedRole_AssemblyConnector.providedInterface__OperationProvidedRole
		val informationFlowParameterStereotypeName = "InformationFlowParameter"
		val specificationParametersFeatureName = "specificationParameters"
		val interfaceSpecificationParameters = providedInterface?.getTaggedValues(informationFlowParameterStereotypeName, specificationParametersFeatureName, SpecificationParameter)
		val specificationParameters = if (interfaceSpecificationParameters == null) Collections.emptySet() else new HashSet<SpecificationParameter>(interfaceSpecificationParameters)
		val providedSignatures = providedInterface?.signatures__OperationInterface
		if (providedSignatures != null) {
			for (providedSignature : providedSignatures) {
				var signatureSpecificationParameters = providedSignature.getTaggedValues(informationFlowParameterStereotypeName, specificationParametersFeatureName, SpecificationParameter)
				specificationParameters.addAll(signatureSpecificationParameters)
			}
		}
		return specificationParameters
	}
	
	private def List<ParametersAndDataPair> getParametersAndDataPairsForProvidedInterfaceOfConnector(AssemblyConnector connector) {
		val providedInterface = connector.providedRole_AssemblyConnector.providedInterface__OperationProvidedRole
		val informationFlowStereotypeName = "InformationFlow"
		val parametersAndDataPairsFeatureName = "parametersAndDataPairs"
		if (providedInterface == null) {
			return Collections.emptyList() 
		}
		val parametersAndDataPairs = providedInterface.getTaggedValues(informationFlowStereotypeName, parametersAndDataPairsFeatureName, ParametersAndDataPair)
		val providedSignatures = providedInterface.signatures__OperationInterface
		if (providedSignatures != null) {
			for (providedSignature : providedSignatures) {
				var signatureParametersAndDataPairs = providedSignature.getTaggedValues(informationFlowStereotypeName, parametersAndDataPairsFeatureName, ParametersAndDataPair)
				parametersAndDataPairs.addAll(signatureParametersAndDataPairs)
			}
		}
		return parametersAndDataPairs
	}
	
	private def List<ParameterizedDataSetMapEntry> getDataSetMapEntriesWithUnassignedParametersForProvidedInterfaceOfConnector(AssemblyConnector connector) {
		val parametersAndDataPairs = getParametersAndDataPairsForProvidedInterfaceOfConnector(connector)		
		val dataSetMapEntriesWithUnassignedParameters = newArrayList()
		for (parametersAndDataPair : parametersAndDataPairs) {
			val parameterizedDataSetMapEntries = parametersAndDataPair.dataTargets.filter(typeof(ParameterizedDataSetMapEntry))
			dataSetMapEntriesWithUnassignedParameters.addAll(parameterizedDataSetMapEntries)
		}
		return dataSetMapEntriesWithUnassignedParameters
	}
	
	private def getAssignmentsAtConnector(Connector connector) {
		val informationFlowAssignmentStereotypeName = "InformationFlowParameterAssignment"
		val substiutionsFeatureName = "assignments"
		return connector.getTaggedValues(informationFlowAssignmentStereotypeName, substiutionsFeatureName, AbstractSpecificationParameterAssignment)
	}
	
	/** CAUTION SIDE-EFFECTS: if unassignedSpecificationParameters or dataSetMapEntriesWithUnassignedParameters are provided, they are changed!
	 * 
	 *@param unassignedSpecificationParameters optional
	 */
	private def String generateInformationFlowForAssignments(Iterable<AbstractSpecificationParameterAssignment> assignments, AssemblyConnector connector, Set<SpecificationParameter> unassignedSpecificationParameters, List<ParameterizedDataSetMapEntry> dataSetMapEntriesWithUnassignedParameters) {
		var contents = ""
		for (assignment : assignments) {
			val assignedParameters = assignment.specificationParametersToReplace
			var instanceCommentOpening = ""
			var instanceCommentClosing = ""
			var newLine = ""
			if (userConfig.generateComments) {
				instanceCommentOpening = generateInstanceCommentOpening(assignment)
				instanceCommentClosing = generateInstanceCommentClosing(assignment)
				newLine = generateNewLine()
			}
			val roleSpecificRelationName = "connectorSpecificParametersAndDataPairs"
			val connectorID = generateID(connector)
			val parametersAndDataPairName = "parametersAndDataPair"
			val parametersAndDataPairs = getParametersAndDataPairsForProvidedInterfaceOfConnector(connector)
			val idsOfNewPairs = new ArrayList<String>()
			for (parametersAndDataPair : parametersAndDataPairs) {
				val currentDataTargets = new BasicEList(parametersAndDataPair.dataTargets)
				for (currentDataTarget : currentDataTargets) {
					var String replacement = null
					if (assignedParameters.contains(currentDataTarget)
								&& assignment instanceof SpecificationParameter2DataSetAssignment) {
						// replacement for data parameter
						val specificationParameterAssignment = assignment as SpecificationParameter2DataSetAssignment
						replacement = specificationParameterAssignment.assignedDataSet.name
						unassignedSpecificationParameters?.remove(currentDataTarget)
					} else if (currentDataTarget instanceof ParameterizedDataSetMapEntry 
								&& assignment instanceof DataSetMapParameter2KeyAssignment) {
						val parameterizedDataTarget = currentDataTarget as ParameterizedDataSetMapEntry
						val dataSetMapParameterAssignment = assignment as DataSetMapParameter2KeyAssignment
						val keyParameter = parameterizedDataTarget.parameter
						if (assignedParameters.contains(keyParameter)) {
							// replacement for data set map entries for which the key parameter is assigned
							val parameterizedMap = parameterizedDataTarget.map
							val assignedKey = dataSetMapParameterAssignment.assignedKey
							var dataSetMapEntry = getFromMapValuedMap(this.dataSetMapAndKey2Entry, parameterizedMap, assignedKey)
							if (dataSetMapEntry == null) {
								dataSetMapEntry = DataFactoryImpl.eINSTANCE.createDataSetMapEntry
								dataSetMapEntry.map = parameterizedMap
								dataSetMapEntry.name = assignedKey
								val container = parameterizedMap.eContainer
								if (container instanceof ConfidentialitySpecification) {
									val confidentialitySpecification = container as ConfidentialitySpecification
									confidentialitySpecification.dataIdentifier.add(dataSetMapEntry)
									contents += generateInstancePredicate(dataSetMapEntry)
									val relationName = "dataIdentifier"
									contents += generateRelation(relationName, generateID(confidentialitySpecification), generateID(dataSetMapEntry))
								} else {
									throw new IllegalStateException("The parameterized map ' " + parameterizedMap + "' has to be contained in a confidentiality specification not in '" + container + "'!")
								}	
							}
							replacement = "[" + generateID(dataSetMapEntry) + "]"
							unassignedSpecificationParameters?.remove(keyParameter)
							dataSetMapEntriesWithUnassignedParameters?.remove(parameterizedDataTarget)
						}
					}
					if (replacement != null) {
						// we will now generate special parametersAndDataPairs relations
						// which are only concerning the provided role of the connector
						val idOfNewPair = generateIDValue(parametersAndDataPair, generateID(parametersAndDataPair) + "_substSpec_" + currentDataTarget + " <- " + replacement)
						idsOfNewPairs.add(idOfNewPair)
						// FIXME MK use generatePredicate or generateRelation
						val instanceContent = parametersAndDataPairName + logConfig.generatePredicateOpening + idOfNewPair + logConfig.generatePredicateClosing
						val sourcesFeatureName = "parameterSources"
						val sourcesFeature = parametersAndDataPair.eClass.getEStructuralFeature(sourcesFeatureName)
						val sourcesValue = generateSingleFeatureValue(parametersAndDataPair, sourcesFeature)
						val sourcesContent = generateRelation(sourcesFeatureName, idOfNewPair, sourcesValue)
						val targetsFeatureName = "dataTargets"
						// do the actual assignment by using the replacement instead of the data target value
						val targetsValue = replacement
						val targetsContent = generateRelation(targetsFeatureName, idOfNewPair, targetsValue)
						contents += newLine + instanceCommentOpening + instanceContent + newLine + sourcesContent + newLine + targetsContent + instanceCommentClosing + newLine
					}
				}
			}
			if (idsOfNewPairs.size > 0) {
				val roleValue = idsOfNewPairs.toString
				val roleContent = generateRelation(roleSpecificRelationName, connectorID, roleValue)
				contents += newLine + instanceCommentOpening + roleContent + instanceCommentClosing + newLine
			}
		}
		return contents
	}
	
	private def dispatch String generateInformationFlowForMissingAssignment(AssemblyConnector connector, ParameterizedDataSetMapEntry unassignedDataSetMapEntry) {
			// prepare fake assignments for all unassignedSpecificationParameters and pairs: 
			// if datatarget is ParameterizedDataSetMapEntry then substitute with all indices plus "others"
			val dataSetMap = unassignedDataSetMapEntry.map
			val unassignedSpecificationParameter = unassignedDataSetMapEntry.getParameter
			val usedKeys = getUsedKeysForDataSetMap(dataSetMap)
			val fakeAssignments = new ArrayList<AbstractSpecificationParameterAssignment>(usedKeys.size + 1)
			for (usedKey : usedKeys) {
				fakeAssignments.add(createFakeDataSetMapParameter2KeyAssignment(unassignedSpecificationParameter, usedKey))
			}
			fakeAssignments.add(createFakeDataSetMapParameter2KeyAssignment(unassignedSpecificationParameter, "others"))
			return generateInformationFlowForAssignments(fakeAssignments, connector, null, null)
	}
	
	private def AbstractSpecificationParameterAssignment createFakeDataSetMapParameter2KeyAssignment(SpecificationParameter specificationParameterToReplace, String assignedKey) {
		val fakeAssignment = SystemFactory.eINSTANCE.createDataSetMapParameter2KeyAssignment
		fakeAssignment.getSpecificationParametersToReplace().add(specificationParameterToReplace)
		fakeAssignment.assignedKey = assignedKey
		return fakeAssignment
	}
	
	private def dispatch String generateInformationFlowForMissingAssignment(AssemblyConnector connector, SpecificationParameter unassignedSpecificationParameter) {
		// prepare fake assignments for all unassignedSpecificationParameters and pairs: 
		// if datatarget is normal SpecificationParameter then substitute with all DataSets
		val usedDataSets = getUsedDataSets()
		val fakeAssignments = new ArrayList<AbstractSpecificationParameterAssignment>(usedDataSets.size)
		for (usedDataSet : usedDataSets) {
			fakeAssignments.add(createFakeSpecificationParameter2DataSetAssignment(unassignedSpecificationParameter, usedDataSet))
		}
		return generateInformationFlowForAssignments(fakeAssignments, connector, null, null)
	}
	
	private def AbstractSpecificationParameterAssignment createFakeSpecificationParameter2DataSetAssignment(SpecificationParameter specificationParameterToReplace, DataSet assignedDataSet) {
		val fakeAssignment = SystemFactory.eINSTANCE.createSpecificationParameter2DataSetAssignment
		fakeAssignment.getSpecificationParametersToReplace().add(specificationParameterToReplace)
		fakeAssignment.assignedDataSet = assignedDataSet
		return fakeAssignment
	}
	
	override generateFeatureValues(EObject e, EStructuralFeature feature) {
		return generateFeatureValuesCorrectly(e, feature)
	}
	
	def dispatch List<String> generateFeatureValuesCorrectly(EObject e, EStructuralFeature feature) {
		return super.generateFeatureValues(e, feature)
	}
		
	def dispatch List<String> generateFeatureValuesCorrectly(ParametersAndDataPair padsp, EReference reference) {
		// only generate relations for those dataTargets that are not parameterized
		// i.e. skip all parameterized dataTargets
		val dataTargetsName = "dataTargets"
		if (reference.name?.equals(dataTargetsName)) {
			val dataTargets = padsp.eGet(reference) as List<DataIdentifying>
			val unparameterizedDataTargets = new BasicEList<DataIdentifying>(dataTargets.size)
			for (dataTarget : dataTargets) {
				if (dataTarget instanceof UnparameterizedDataIdentifying) {
					unparameterizedDataTargets.add(dataTarget)
				}
			}
			return generateManyFeatureValues(padsp,reference,unparameterizedDataTargets)
		}
		return super.generateFeatureValues(padsp,reference)
	}
	
	private def String getSizeOfId(String parameterName) {
		var sizeOfId = "sizeOf_" + parameterName + "_"
		if (userConfig.simplifyIDs) {
			sizeOfId = nameConfig.getSimpleIDValue(sizeOfId)?.toString
		}
		return sizeOfId
	}
}