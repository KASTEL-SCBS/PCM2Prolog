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
import edu.kit.kastel.scbs.confidentiality.system.SpecificationParameterEquation
import edu.kit.kastel.scbs.confidentiality.system.SystemFactory
import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.common.util.BasicEList
import org.eclipse.emf.ecore.EObject
import org.eclipse.internal.xtend.util.Triplet
import org.eclipse.xtend.lib.annotations.Accessors
import org.palladiosimulator.pcm.core.composition.AssemblyConnector
import org.palladiosimulator.pcm.core.composition.AssemblyContext
import org.palladiosimulator.pcm.core.composition.Connector
import org.palladiosimulator.pcm.repository.OperationInterface

import static extension edu.kit.ipd.sdq.commons.util.java.lang.MapUtil.*
import static extension edu.kit.ipd.sdq.commons.util.org.eclipse.emf.ecore.EObjectUtil.*
import static extension edu.kit.ipd.sdq.commons.util.org.palladiosimulator.mdsdprofiles.api.StereotypeAPIUtil.*
import static extension edu.kit.ipd.sdq.commons.util.org.palladiosimulator.pcm.core.composition.AssemblyContextUtil.*
import static extension edu.kit.ipd.sdq.commons.util.org.palladiosimulator.pcm.core.composition.ConnectorUtil.*

class SpecificationParameterRemover {
	// FIXME MK replace all three maps with org.apache.commons.collections4.SetValuedMap
	private val Map<SpecificationParameter, Set<String>> dataParam2KeyMap = newHashMap()
	private val Map<DataSetMap, Set<SpecificationParameter>> dataSetMap2ParamMap = newHashMap()
	private val Map<DataSetMap, Set<String>> dataSetMap2Keys = newHashMap()
	private val Map<DataSetMap, Map<String,DataSetMapEntry>> dataSetMapAndKey2Entry = newHashMap()
	
	@Accessors(PUBLIC_GETTER)
	private val Collection<Pair<ConfidentialitySpecification, DataSetMapEntry>> assignmentSpecificDataSetMapEntries = newArrayList()
	@Accessors(PUBLIC_GETTER)
	private val Map<Connector, Set<Triplet<ParametersAndDataPair, ParameterizedDataSetMapEntry, UnparameterizedDataIdentifying>>> assignmentSpecificParametersAndDataPairs = newHashMap()
	
	private var Collection<DataSet> dataSets = new HashSet()
	
	private val Map<Connector, List<AbstractSpecificationParameterAssignment>> equationReplacingAssignments = newHashMap()
		
	
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
	
	private def List<SpecificationParameterEquation>  getEquationsAtAssemblyContext(AssemblyContext assemblyContext) {
		val informationFlowEquationsStereotypeName = "InformationFlowParameterEquation"
		val equationsFeatureName = "equations"
		return assemblyContext.getTaggedValues(informationFlowEquationsStereotypeName, equationsFeatureName, SpecificationParameterEquation)
	}
	
	private def List<AbstractSpecificationParameterAssignment> addAssignmentsAtConnector(Connector connector, List<AbstractSpecificationParameterAssignment> equations) {
		val informationFlowAssignmentStereotypeName = "InformationFlowParameterAssignment"
		val assignmentsFeatureName = "assignments"
		return connector.addTaggedValues(informationFlowAssignmentStereotypeName, assignmentsFeatureName, equations, AbstractSpecificationParameterAssignment)
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
		if (usedParameters != null) {
			for (usedParameter : usedParameters) {
				val usedKeys = this.dataParam2KeyMap.get(usedParameter)
				if (usedKeys != null) {
					possibleKeys.addAll(usedKeys)
				}
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
			for (unassignedSpecificationParameter : unassignedSpecificationParameters) {
				// if a parameter is not assigned, the effect of the relations that we generate for the missing
				// assignment is the same as if we would have directly generated the relations for _all_ existing data sets and _all_ existing data set map entries during the generation for the interface
				prepareInformationFlowForMissingAssignment(ac, unassignedSpecificationParameter)			
			}
			// TODO MK remove this code duplication of this two loops by concatenating the iterators using Guava Iterators.concat
			for (dataSetMapEntryWithUnassignedParameter : dataSetMapEntriesWithUnassignedParameters) {
				// if a parameter is not assigned, the effect of the relations that we generate for the missing
				// assignment is the same as if we would have directly generated the relations for _all_ existing data sets and _all_ existing data set map entries during the generation for the interface
				prepareInformationFlowForMissingAssignment(ac, dataSetMapEntryWithUnassignedParameter)			
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
		val assignmentsFeatureName = "assignments"
		return connector.getTaggedValues(informationFlowAssignmentStereotypeName, assignmentsFeatureName, AbstractSpecificationParameterAssignment)
	}
	
	/** CAUTION SIDE-EFFECTS: if unassignedSpecificationParameters or dataSetMapEntriesWithUnassignedParameters are provided, they are changed!
	 * 
	 *@param unassignedSpecificationParameters optional
	 */
	private def UnparameterizedDataIdentifying prepareInformationFlowForAssignments(Iterable<AbstractSpecificationParameterAssignment> assignments, AssemblyConnector connector, Set<SpecificationParameter> unassignedSpecificationParameters, List<ParameterizedDataSetMapEntry> dataSetMapEntriesWithUnassignedParameters) {
		for (assignment : assignments) {
			val assignedParameters = assignment.specificationParametersToReplace
			val parametersAndDataPairs = getParametersAndDataPairsForProvidedInterfaceOfConnector(connector)
			for (parametersAndDataPair : parametersAndDataPairs) {
				val currentDataTargets = new BasicEList(parametersAndDataPair.dataTargets)
				for (currentDataTarget : currentDataTargets) {
					val parameterReplacementPair = getParameterAndReplacementForCurrentDataTarget(dataSetMapEntriesWithUnassignedParameters, assignedParameters, currentDataTarget, assignment)
					val assignedParameter = parameterReplacementPair?.key
					val replacement = parameterReplacementPair?.value
					if (replacement != null) {
						unassignedSpecificationParameters?.remove(assignedParameter)
						// we will now add special parametersAndDataPairs relations
						// which are only concerning the provided role of the connector
						addToSetValuedMap(this.assignmentSpecificParametersAndDataPairs, connector, new Triplet(parametersAndDataPair, currentDataTarget, replacement))
					}
					return replacement
				}
			}
		}
	}
	
	private def dispatch Pair<SpecificationParameter,UnparameterizedDataIdentifying> getParameterAndReplacementForCurrentDataTarget(List<ParameterizedDataSetMapEntry> dataSetMapEntriesWithUnassignedParameters, Collection<SpecificationParameter> assignedParameters, DataIdentifying currentDataTarget, AbstractSpecificationParameterAssignment assignment) {
		return new Pair(null,null)
	}
	
	private def dispatch Pair<SpecificationParameter,UnparameterizedDataIdentifying> getParameterAndReplacementForCurrentDataTarget(List<ParameterizedDataSetMapEntry> dataSetMapEntriesWithUnassignedParameters, Collection<SpecificationParameter> assignedParameters, DataIdentifying currentDataTarget, SpecificationParameter2DataSetAssignment specificationParameterAssignment) {
		if (assignedParameters.contains(currentDataTarget)) {
			// replacement for data parameter
			return new Pair(currentDataTarget, specificationParameterAssignment.assignedDataSet)
		}
	}
	
	private def dispatch Pair<SpecificationParameter,UnparameterizedDataIdentifying> getParameterAndReplacementForCurrentDataTarget(List<ParameterizedDataSetMapEntry> dataSetMapEntriesWithUnassignedParameters, Collection<SpecificationParameter> assignedParameters, ParameterizedDataSetMapEntry parameterizedDataTarget, DataSetMapParameter2KeyAssignment dataSetMapParameterAssignment) {
		var UnparameterizedDataIdentifying replacement = null
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
			dataSetMapEntriesWithUnassignedParameters?.remove(parameterizedDataTarget)
		}
		return new Pair(keyParameter,replacement)
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
	
	public def void preprocessSpecificationParameterEquationsAtAssemblyContext(AssemblyContext assemblyContext) {
		var boolean assignmentAdded = false
		do {
			assignmentAdded = false
			val equationsAtAC = getEquationsAtAssemblyContext(assemblyContext)
			for (equationAtAC : equationsAtAC) {
				var providedNotRequired = true
				val assignmentsForEquatedProvidedParameter = getAssignmentsForEquatedParameter(assemblyContext, equationAtAC, providedNotRequired)
				providedNotRequired = false
				val assignmentsForEquatedRequiredParameter = getAssignmentsForEquatedParameter(assemblyContext, equationAtAC, providedNotRequired)
				// FIXME check in map for each connector whether it is replacing by obtaining a map from connector to assignments in getAssignmentsForEquatedParameter
				val assignmentsForProvidedEmptyOrReplacing = assignmentsForEquatedProvidedParameter?.onlyEmptyCollectionsMapped || this.equationReplacingAssignments?.containsAll(assignmentsForEquatedProvidedParameter)
				val assignmentsForRequiredEmptyOrReplacing = assignmentsForEquatedRequiredParameter?.onlyEmptyCollectionsMapped || this.equationReplacingAssignments?.containsAll(assignmentsForEquatedRequiredParameter)
				val flattenedAssignmentsForEquatedProvidedParameter = assignmentsForEquatedProvidedParameter?.values.flatten().toList
				val flattenedAssignmentsForEquatedRequiredParameter = assignmentsForEquatedRequiredParameter?.values.flatten().toList
				
				// we have to distinguish assignments that were added by the user and 
				// assignments that were added by us: four cases are possible
				if (assignmentsForProvidedEmptyOrReplacing) {
					if (assignmentsForRequiredEmptyOrReplacing) {
						// 1. no user assignments neither on provided nor on required side:
						// copy in both directions
						providedNotRequired = true
						assignmentAdded = copyAssignments(assemblyContext, flattenedAssignmentsForEquatedRequiredParameter, providedNotRequired) || assignmentAdded
						providedNotRequired = false
						assignmentAdded = copyAssignments(assemblyContext, flattenedAssignmentsForEquatedProvidedParameter, providedNotRequired) || assignmentAdded
					} else {
						// 2. user assignments only at required side: 
						// copy assignments collected at all connectors on required side to every connector on provided side
						providedNotRequired = true
						assignmentAdded = copyAssignments(assemblyContext, flattenedAssignmentsForEquatedRequiredParameter, providedNotRequired) || assignmentAdded
					}
				} else {
					if (assignmentsForRequiredEmptyOrReplacing) {
						// 3. user assignments only at provided side: 
						// symmetric to case 2.
						providedNotRequired = false
						assignmentAdded = copyAssignments(assemblyContext, flattenedAssignmentsForEquatedProvidedParameter, providedNotRequired) || assignmentAdded
					} else {
						// 4. user assignments on both sides: not allowed! in the future we could demand that they have to be the same for every connector at every side or that one has to be stricter than the other 
						throw new RuntimeException("Parameter equations are only allowed if the connectors that connect interfaces with the equated specification parameters only have assignments either on the provided or on the required side of the assembly context to which the equation is applied! This is not true for the assembly context '" + assemblyContext + "' and the equation '" + equationAtAC + "'!")
					}
				}
			}
		} while (assignmentAdded)
	}
	
	private def Map<Connector,List<AbstractSpecificationParameterAssignment>> getAssignmentsForEquatedParameter(AssemblyContext assemblyContext, SpecificationParameterEquation equation, boolean providedNotRequired) {	
		val namesOfInterfacesForWhichParameterIsEquated = if (providedNotRequired) equation.providedInterfaceNames else equation.requiredInterfaceNames
		val equatedParameter = if (providedNotRequired) equation.providedSpecificationParameter else equation.requiredSpecificationParameter
		val interfacesOfEquatedParameter = getInterfacesOfEquatedParameter(assemblyContext, namesOfInterfacesForWhichParameterIsEquated, providedNotRequired)
		val connectors = assemblyContext.getAssemblyOrDelegationConnectors(providedNotRequired)
		val Map<Connector,List<AbstractSpecificationParameterAssignment>> assignmentsForEquatedParameterAtAllConnectors = new HashMap()
		for (connector : connectors) {
			val connectedInterface = connector.getOperationInterface(providedNotRequired)
			val interfaceOfEquatedParameter = interfacesOfEquatedParameter?.contains(connectedInterface)
			if (interfaceOfEquatedParameter) {
				val assignmentsAtConnector = getAssignmentsAtConnector(connector)
				for (assignmentAtConnector : assignmentsAtConnector) {
					val hasAssignmentForEquatedProvidedParameter = switch assignmentAtConnector {
						DataSetMapParameter2KeyAssignment : assignmentAtConnector?.specificationParametersToReplace?.contains(equatedParameter)
						// FIXME support SpecificationParameter2DataSetAssignment
					}
					if (hasAssignmentForEquatedProvidedParameter) {
						assignmentsForEquatedParameterAtAllConnectors.add(connector, assignmentAtConnector, [newArrayList()])
					}
				}
			}
		}
		return assignmentsForEquatedParameterAtAllConnectors
	}
	
	private def List<OperationInterface> getInterfacesOfEquatedParameter(AssemblyContext assemblyContext, List<String> namesOfInterfacesForWhichParameterIsEquated, boolean providedNotRequired) {
		val interfaces = assemblyContext.getOperationInterfaces(providedNotRequired)
		if (namesOfInterfacesForWhichParameterIsEquated?.size == 1 && namesOfInterfacesForWhichParameterIsEquated.get(0) == "*") {
			return interfaces.toList
		} else {
			return interfaces?.filter[namesOfInterfacesForWhichParameterIsEquated?.contains(it?.entityName)].toList
		}
	}
	
	private def boolean copyAssignments(AssemblyContext assemblyContext, List<AbstractSpecificationParameterAssignment> assignmentsToCopy, boolean providedNotRequired) {
		var boolean assignmentAdded = false
		val connectorsForAddingAssignments = assemblyContext.getAssemblyOrDelegationConnectors(providedNotRequired)
		for (connectorForAddingAssignments : connectorsForAddingAssignments) {
			// FIXME MK check whether assignment is already there and return assignmentAdded if not
			// do this when adding the tagged values
			val allAssignmentsAlreadyAdded = this.equationReplacingAssignments.containsAll(connectorForAddingAssignments, assignmentsToCopy)
			if (!allAssignmentsAlreadyAdded) {
				addAssignmentsAtConnector(connectorForAddingAssignments, assignmentsToCopy) 
				this.equationReplacingAssignments.addAll(connectorForAddingAssignments, assignmentsToCopy, [new ArrayList()])
				assignmentAdded = true
			}
		}
		return assignmentAdded
	}
}