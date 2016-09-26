package edu.kit.kastel.scbs.pcm2prologxsb.generator

import edu.kit.kastel.scbs.confidentiality.ConfidentialitySpecification
import edu.kit.kastel.scbs.confidentiality.data.DataIdentifying
import edu.kit.kastel.scbs.confidentiality.data.DataSet
import edu.kit.kastel.scbs.confidentiality.data.DataSetMap
import edu.kit.kastel.scbs.confidentiality.data.DataSetMapEntry
import edu.kit.kastel.scbs.confidentiality.data.ParameterizedDataSetMapEntry
import edu.kit.kastel.scbs.confidentiality.data.SpecificationParameter
import edu.kit.kastel.scbs.confidentiality.data.UnparameterizedDataIdentifying
import edu.kit.kastel.scbs.confidentiality.data.impl.DataFactoryImpl
import edu.kit.kastel.scbs.confidentiality.repository.ParametersAndDataPair
import edu.kit.kastel.scbs.confidentiality.system.AbstractSpecificationParameterAssignment
import edu.kit.kastel.scbs.confidentiality.system.DataSetMapParameter2KeyAssignment
import edu.kit.kastel.scbs.confidentiality.system.SpecificationParameter2DataSetAssignment
import edu.kit.kastel.scbs.confidentiality.system.SystemFactory
import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.common.util.BasicEList
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtend.lib.annotations.Accessors
import org.palladiosimulator.pcm.core.composition.AssemblyConnector
import org.palladiosimulator.pcm.core.composition.Connector
import tools.vitruv.framework.util.datatypes.Quadruple

import static extension edu.kit.ipd.sdq.commons.util.org.eclipse.emf.ecore.EObjectUtil.*
import static extension edu.kit.ipd.sdq.commons.util.org.palladiosimulator.mdsdprofiles.api.StereotypeAPIUtil.*
import org.eclipse.internal.xtend.util.Triplet

class SpecificationParameterRemover {
	// FIXME MK replace all three maps with org.apache.commons.collections4.SetValuedMap
	private val Map<SpecificationParameter, Set<String>> dataParam2KeyMap = newHashMap()
	private val Map<DataSetMap, Set<SpecificationParameter>> dataSetMap2ParamMap = newHashMap()
	private val Map<DataSetMap, Set<String>> dataSetMap2Keys = newHashMap()
	private val Map<DataSetMap, Map<String,DataSetMapEntry>> dataSetMapAndKey2Entry = newHashMap()
	
	@Accessors(PUBLIC_GETTER)
	private val Collection<Pair<ConfidentialitySpecification, DataSetMapEntry>> assignmentSpecificDataSetMapEntries = newArrayList()
	@Accessors(PUBLIC_GETTER)
	private val Map<Connector, Set<Triplet<ParametersAndDataPair, DataIdentifying, UnparameterizedDataIdentifying>>> assignmentSpecificParametersAndDataPairs = newHashMap()
	
	private var Collection<DataSet> dataSets = new HashSet()
	
	def public void preProcessFirstLevelContentsToBuildUpMaps(List<EObject> firstLevelContents) {
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
	
	// FIXME MK GENERALIZE THIS SO THAT IT ALSO WORKS FOR DELEGATION CONNECTORS
	def public void prepareInformationFlowSpecificationsForParameterAssignments(AssemblyConnector ac) {
		// at the beginning the variable unassignedSpecificationParameters contains all data parameters (assigned or not)
		val unassignedSpecificationParameters = getSpecificationParametersForProvidedInterfaceOfConnector(ac)
		val dataSetMapEntriesWithUnassignedParameters = getDataSetMapEntriesWithUnassignedParametersForProvidedInterfaceOfConnector(ac)
		if (!unassignedSpecificationParameters.isEmpty) {
			val assignments = getAssignmentsAtConnector(ac)
			// if a parameter is assigned, the effect of the relations that we generate for the assignment
			// is the same as if we would have directly generated the relations for the assigned data sets or
			// data set map entries during the generation of the other relations for the provided interface
			prepareInformationFlowForAssignments(assignments, ac, unassignedSpecificationParameters, dataSetMapEntriesWithUnassignedParameters)
			// now the variable unassignedSpecificationParameters really contains only those data parameters that were not assigned
			// and dataSetMapEntriesWithUnassignedParameters really contains only such entries
			val unassignedSpecificationParameterIterator = unassignedSpecificationParameters.iterator
			while (unassignedSpecificationParameterIterator.hasNext) {
				val unassignedSpecificationParameter = unassignedSpecificationParameterIterator.next
				// if a parameter is not assigned, the effect of the relations that we generate for the missing
				// assignment is the same as if we would have directly generated the relations for _all_ existing data sets and _all_ existing data set map entries during the generation for the interface
				prepareInformationFlowForMissingAssignment(ac, unassignedSpecificationParameter)			
				unassignedSpecificationParameterIterator.remove
			}
			// FIXME MK remove this code duplication of this two while loops by concatenating the iterators using Guava Iterators.concat
			val dataSetMapEntriesWithUnassignedParametersIterator = dataSetMapEntriesWithUnassignedParameters.iterator
			while (dataSetMapEntriesWithUnassignedParametersIterator.hasNext) {
				val dataSetMapEntryWithUnassignedParameter = dataSetMapEntriesWithUnassignedParametersIterator.next
				// if a parameter is not assigned, the effect of the relations that we generate for the missing
				// assignment is the same as if we would have directly generated the relations for _all_ existing data sets and _all_ existing data set map entries during the generation for the interface
				prepareInformationFlowForMissingAssignment(ac, dataSetMapEntryWithUnassignedParameter)			
				dataSetMapEntriesWithUnassignedParametersIterator.remove
			}
			if (!unassignedSpecificationParameters.isEmpty) {
				throw new RuntimeException("The unassigned data parameters '" + unassignedSpecificationParameters + "' were not processed!")
			}
		}
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
	private def void prepareInformationFlowForAssignments(Iterable<AbstractSpecificationParameterAssignment> assignments, AssemblyConnector connector, Set<SpecificationParameter> unassignedSpecificationParameters, List<ParameterizedDataSetMapEntry> dataSetMapEntriesWithUnassignedParameters) {
		for (assignment : assignments) {
			val assignedParameters = assignment.specificationParametersToReplace
			val parametersAndDataPairs = getParametersAndDataPairsForProvidedInterfaceOfConnector(connector)
			val idsOfNewPairs = new ArrayList<String>()
			for (parametersAndDataPair : parametersAndDataPairs) {
				val currentDataTargets = new BasicEList(parametersAndDataPair.dataTargets)
				for (currentDataTarget : currentDataTargets) {
					var UnparameterizedDataIdentifying replacement = null
					if (assignedParameters.contains(currentDataTarget)
								&& assignment instanceof SpecificationParameter2DataSetAssignment) {
						// replacement for data parameter
						val specificationParameterAssignment = assignment as SpecificationParameter2DataSetAssignment
						replacement = specificationParameterAssignment.assignedDataSet
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
									this.assignmentSpecificDataSetMapEntries.add(new Pair(confidentialitySpecification,dataSetMapEntry))
								} else {
									throw new IllegalStateException("The parameterized map ' " + parameterizedMap + "' has to be contained in a confidentiality specification not in '" + container + "'!")
								}	
							}
							replacement = dataSetMapEntry
							unassignedSpecificationParameters?.remove(keyParameter)
							dataSetMapEntriesWithUnassignedParameters?.remove(parameterizedDataTarget)
						}
					}
					if (replacement != null) {
						// we will now add special parametersAndDataPairs relations
						// which are only concerning the provided role of the connector
						addToSetValuedMap(this.assignmentSpecificParametersAndDataPairs, connector, new Triplet(parametersAndDataPair, currentDataTarget, replacement))
					}
				}
			}
		}
	}
	
	private def dispatch void prepareInformationFlowForMissingAssignment(AssemblyConnector connector, ParameterizedDataSetMapEntry unassignedDataSetMapEntry) {
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
			prepareInformationFlowForAssignments(fakeAssignments, connector, null, null)
	}
	
	private def AbstractSpecificationParameterAssignment createFakeDataSetMapParameter2KeyAssignment(SpecificationParameter specificationParameterToReplace, String assignedKey) {
		val fakeAssignment = SystemFactory.eINSTANCE.createDataSetMapParameter2KeyAssignment
		fakeAssignment.getSpecificationParametersToReplace().add(specificationParameterToReplace)
		fakeAssignment.assignedKey = assignedKey
		return fakeAssignment
	}
	
	private def dispatch void prepareInformationFlowForMissingAssignment(AssemblyConnector connector, SpecificationParameter unassignedSpecificationParameter) {
		// prepare fake assignments for all unassignedSpecificationParameters and pairs: 
		// if datatarget is normal SpecificationParameter then substitute with all DataSets
		val usedDataSets = getUsedDataSets()
		val fakeAssignments = new ArrayList<AbstractSpecificationParameterAssignment>(usedDataSets.size)
		for (usedDataSet : usedDataSets) {
			fakeAssignments.add(createFakeSpecificationParameter2DataSetAssignment(unassignedSpecificationParameter, usedDataSet))
		}
		prepareInformationFlowForAssignments(fakeAssignments, connector, null, null)
	}
	
	private def AbstractSpecificationParameterAssignment createFakeSpecificationParameter2DataSetAssignment(SpecificationParameter specificationParameterToReplace, DataSet assignedDataSet) {
		val fakeAssignment = SystemFactory.eINSTANCE.createSpecificationParameter2DataSetAssignment
		fakeAssignment.getSpecificationParametersToReplace().add(specificationParameterToReplace)
		fakeAssignment.assignedDataSet = assignedDataSet
		return fakeAssignment
	}
}