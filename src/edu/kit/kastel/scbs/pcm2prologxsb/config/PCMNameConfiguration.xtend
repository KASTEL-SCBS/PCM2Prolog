package edu.kit.kastel.scbs.pcm2prologxsb.config

import edu.kit.ipd.sdq.mdsd.ecore2log.config.DefaultMetamodel2LogNameConfiguration
import edu.kit.kastel.scbs.confidentiality.repository.ParametersAndDataPair
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.palladiosimulator.pcm.core.entity.NamedElement
import org.palladiosimulator.pcm.repository.Parameter
import org.palladiosimulator.pcm.repository.PrimitiveDataType
import org.palladiosimulator.pcm.resourceenvironment.ResourceEnvironment

class PCMNameConfiguration extends DefaultMetamodel2LogNameConfiguration {
	override getFileExtension() {
		return "P"
	}
	
	override getFeatureName(EObject object, EStructuralFeature feature) {
		val featureName = super.getFeatureName(object, feature)
		if (featureName != null) {
			val indexOfFirstUnderline = featureName.indexOf("_")
			if (indexOfFirstUnderline > -1) {
				val keepOriginalFeatureNameSet = #{ 'assemblyContext_AllocationContext' }
				if (keepOriginalFeatureNameSet.contains(featureName)) {
					return featureName
				} else {
					return featureName.substring(0,indexOfFirstUnderline)
				}
			}
		}
		return featureName
	}
		
	override replaceAttributeValueWithIDAttribute(EObject e, EAttribute attribute, Object attributeValue) {
		if (isParameterSourcesAttribute(attribute) && e instanceof ParametersAndDataPair) {
			return false // !isReturnParameter(attributeValue)
		}
		return super.replaceAttributeValueWithIDAttribute(e, attribute, attributeValue)
	}
	
	override getNameValue(EObject e) {
		return getCorrectNameValue(e)
	}
	
	def dispatch private String getCorrectNameValue(EObject e) {
		return super.getNameValue(e)
	}
	
	def dispatch private String getCorrectNameValue(NamedElement ne) {
		return ne.entityName
	}
	
	def dispatch private String getCorrectNameValue(edu.kit.kastel.scbs.confidentiality.NamedElement ne) {
		return ne.name
	}
	
	def dispatch private String getCorrectNameValue(Parameter p) {
		return p.parameterName
	}
	
	override getIDReplacement(EObject e) {
		return getIDOrReplacement(e)
	}
	
	def dispatch String getIDOrReplacement(EObject e) {
		return super.getIDReplacement(e)
	}
	
	def dispatch String getIDOrReplacement(ResourceEnvironment resourceEnvironment) {
		return resourceEnvironment.entityName
	}
	
	def dispatch String getIDOrReplacement(PrimitiveDataType pdt) {
		return "\"" + pdt.getType().getName + "\""
	}
	
	def dispatch String getIDOrReplacement(Parameter p) {
		val signature = p.operationSignature__Parameter
		val signatureIDAttribute = getIDAttribute(signature)
		val signatureID = signature.eGet(signatureIDAttribute)
		val parameterID = signatureID + "-" + p.parameterName
		return parameterID
	}
	
	// TODO MK change toString handling for Collection and Composite Data Types if necessary
	
	def boolean isParameterSourcesAttribute(EAttribute attribute) {
		return attribute.name?.equals("parameterSources")
	}
	
	def boolean isReturnParameter(Object attributeValue) {
		return attributeValue.equals("\\return")
	}
	
	def dispatch boolean isSizeOfParameter(Object attributeValue) {
		return false
	}
	
	def dispatch boolean isSizeOfParameter(String attributeValue) {
		return attributeValue.startsWith("sizeOf(") && attributeValue.endsWith(")")
	}
	
	def String getParameterNameFromSizeOf(String referencedString) {
		return referencedString.substring("sizeOf(".length,referencedString.length - 1)
	}
}