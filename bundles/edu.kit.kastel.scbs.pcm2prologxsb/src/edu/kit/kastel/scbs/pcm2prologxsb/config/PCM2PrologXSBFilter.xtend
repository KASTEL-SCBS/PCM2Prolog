package edu.kit.kastel.scbs.pcm2prologxsb.config

import edu.kit.ipd.sdq.mdsd.ecore2log.config.DefaultProfiledMetamodel2LogFilter
import org.eclipse.core.runtime.Platform
import org.eclipse.core.runtime.Status
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import edu.kit.kastel.scbs.confidentiality.data.DataSetMapEntry

class PCM2PrologXSBFilter extends DefaultProfiledMetamodel2LogFilter {
	//TODO: Kramersche Softwaretechnik-Magie. Da geht bestimmt was mit Aspekten oder sowas!!!
	val logSkipped = false
	
	override relevantFirstLevelElement(EObject e) {
		return relevantElement(e)
	}
	
	override relevantChild(EObject e) {
		return relevantElement(e)
	}
	
//	override onlyChildrenAreRelevant(EObject e) {
//		if (e instanceof LocationsAndTamperProtectionsPair) {
//			return true
//		}
//		return super.onlyChildrenAreRelevant(e)
//	}
	
	private def boolean relevantElement(EObject e) {
//		return true
		var simpleClassName = e.class.simpleName
		if (simpleClassName != null && simpleClassName.endsWith("Impl")) {
			simpleClassName = simpleClassName.substring(0,simpleClassName.length - "Impl".length)
		}
		return relevantSimpleClassName(simpleClassName)
	}
	
	private def boolean relevantSimpleClassName(String simpleClassName) {
		val classNameWhiteSet = #{
			// repository
			'Repository',
			'BasicComponent',
			'OperationProvidedRole',
			'OperationInterface',
			'OperationSignature',
			'Parameter',
			// system
			'System',
			'AssemblyContext',
			'AssemblyConnector',
			'ProvidedDelegationConnector',
			'RequiredDelegationConnector',
			'OperationProvidedRole',
			'OperationRequiredRole',
			// resource environment
			'ResourceEnvironment',
			'LinkingResource',
			'ResourceContainer',
			// allocation
			'Allocation',
			'AllocationContext',
			// confidentiality
			'ConfidentialitySpecification',
			'CollectionDataType',
			'PrimitiveDataType',
			'CompositeDataType',
			// confidentiality.data
			'DataSet',
			'DataSetMap',
			'SpecificationParameter',
			'DataSetMapEntry',
			'ParameterizedDataSetMapEntry',
			// confidentiality.repository
			'ParametersAndDataPair',
			'AddedServiceParameter',
			// confidentiality.system
			'SpecificationParameter2DataSetAssignment',
			'DataSetMapParameter2KeyAssignment',
			'SpecificationParameterEquation',
			// confidentiality.resources
			'Location',
			'TamperProtection',
			'LocationsAndTamperProtectionsPair',
			// confidentiality.adversary
			'Adversaries',
			'Adversary'
			// confidentiality profile
			// nothing
		}
		if (logSkipped && !classNameWhiteSet.contains(simpleClassName)) {
			val pluginId = "edu.kit.kastel.scbs.pcm2prologxsb"
			val bundle = Platform.getBundle(pluginId)
			val log = Platform.getLog(bundle);
			log.log(new Status(Status.ERROR, pluginId,"skipped className: "  + simpleClassName))
		}
		return classNameWhiteSet.contains(simpleClassName)	
	}
	
	override relevantFeatureFor(EStructuralFeature feature, EObject e) {
//		return true
		val nameFeatureWhiteSet = # {
			DataSetMapEntry
		}

		val featureNameWhiteSet = #{
			// repository
			'components__Repository',
			'providedRoles_InterfaceProvidingEntity',
			'requiredRoles_InterfaceRequiringEntity',
			'providedInterface__OperationProvidedRole',
			'requiredInterface__OperationRequiredRole',
			'interfaces__Repository',
			'parentInterfaces__Interface',
			'signatures__OperationInterface',
			'parameters__OperationSignature',
			'returnType__OperationSignature',
//			'dataType__Parameter',
			// system
			'assemblyContexts__ComposedStructure',
			'connectors__ComposedStructure',
			'encapsulatedComponent__AssemblyContext',
			'requiringAssemblyContext_AssemblyConnector',
			'providingAssemblyContext_AssemblyConnector',
			'requiredRole_AssemblyConnector',
			'providedRole_AssemblyConnector',
			'innerProvidedRole_ProvidedDelegationConnector',
			'outerProvidedRole_ProvidedDelegationConnector',
			'assemblyContext_ProvidedDelegationConnector',
			'innerRequiredRole_RequiredDelegationConnector',
			'outerRequiredRole_RequiredDelegationConnector',
			'assemblyContext_ProvidedDelegationConnector',
			'assemblyContext_RequiredDelegationConnector',
			'providedInterface__OperationProvidedRole',
			// resource environment
			'linkingResources__ResourceEnvironment',
			'connectedResourceContainers_LinkingResource',
			'communicationLinkResourceSpecifications_LinkingResource',
			'communicationLinkResourceType_CommunicationLinkResourceSpecification',
			'resourceContainer_ResourceEnvironment',
			// allocation
			'allocationContexts_Allocation',
			'resourceContainer_AllocationContext',
			'assemblyContext_AllocationContext',
			// confidentiality
			'dataIdentifier',
			'dataSetMaps',
			'parametersAndDataPairs',
			'addedServiceParameters',
			'specificationParameterAssignments',
			'specificationParameterEquations',
			'leftInterfaces',
			'rightInterfaces',
			'locations',
			'tamperProtections',
			'locationsAndTamperProtectionsPairs',
			// confidentiality.data
//			'definingServiceParameter',
			'map',
			'parameter',
			// confidentiality.repository
			'parameterSources',
			'dataTargets',
			// confidentiality.system
			'specificationParametersToReplace',
			'assignedDataSet',
			'assignedKey',
			'leftSpecificationParameter',
			'rightSpecificationParameter',
			// confidentiality.resources
			// nothing
			// confidentiality.adversary
			'adversaries',
			'mayKnowData',
			// confidentiality profile
			'sharing',
			'connectionType',
			'unencryptedData',
			'signatures',
			'assignments',
			'equations',
			'serviceParameters',
			'specificationParameters'
		}
		if (logSkipped && !featureNameWhiteSet.contains(feature.name)) {
			val pluginId = "edu.kit.kastel.scbs.pcm2prologxsb"
			val bundle = Platform.getBundle(pluginId)
			val log = Platform.getLog(bundle);
			log.log(new Status(Status.ERROR, pluginId,"skipped featureName: "  + feature.name))
		}
		if (feature.name.equals("name")) {
			return !nameFeatureWhiteSet.filter[ c | c.isAssignableFrom(e.class)].isEmpty;
		}
		return featureNameWhiteSet.contains(feature.name)
	}
	
	override relevantFeatureValue(String featureValue) {
		val featureValueBlackSet = #{
			'',
			'null',
			'[]'
		}
		return !(featureValue == null || featureValueBlackSet.contains(featureValue))
	}
	
	override relevantProfileNsURI(String profileNamespaceURI) {
		val profileNsURIWhiteSet = #{
			'http://edu.kit.kastel.scbs/pcmconfidentialityprofile'
		}
		return profileNsURIWhiteSet.contains(profileNamespaceURI)
	}
}