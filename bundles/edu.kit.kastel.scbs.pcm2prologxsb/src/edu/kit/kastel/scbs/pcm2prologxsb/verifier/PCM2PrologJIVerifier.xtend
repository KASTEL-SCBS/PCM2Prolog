package edu.kit.kastel.scbs.pcm2prologxsb.verifier

import java.util.Map
import com.ugos.jiprolog.engine.JIPEventListener
import com.ugos.jiprolog.engine.JIPTraceListener
import com.ugos.jiprolog.engine.JIPEvent
import com.ugos.jiprolog.engine.JIPErrorEvent
import com.ugos.jiprolog.engine.JIPTraceEvent
import com.ugos.jiprolog.engine.JIPEngine
import com.ugos.jiprolog.engine.JIPVariable
import com.ugos.jiprolog.engine.JIPTerm
import java.net.URL
import org.eclipse.core.runtime.FileLocator
import org.osgi.framework.Bundle
import org.eclipse.core.runtime.Platform
import java.io.File
import java.io.InputStream
import tools.vitruv.framework.util.datatypes.Quadruple
import org.eclipse.core.resources.IProject
import java.io.ByteArrayInputStream
import java.nio.charset.StandardCharsets
import java.io.SequenceInputStream
import org.eclipse.emf.ecore.EObject
import java.util.List
import java.util.ArrayList
import edu.kit.kastel.scbs.pcm2prologxsb.highlight.ElementsHighlight

//postprocess mit  input files, preprocess inhalte modelldatei EObject, Inhalte iterieren, ecoreUtil getId aufrufen um die ID anzuzeigen, highlighten der Eobjecte mit dem Framework
class PCM2PrologJIVerifier implements JIPEventListener, JIPTraceListener {
	private Map<Object, Integer> fullSimpleIDMap;
	private Map<String, EObject> eObjectsWithID;
	private List<EObject> objectsToHighlight= new ArrayList<EObject>();
	private int m_nQueryHandle;
	private boolean end = false;
	private ElementsHighlight highlighter;
	private static JIPEngine jip=new JIPEngine();

	new(Map<Object, Integer> fullSimpleIDMap,Map<String, EObject> eObjectsWithID,ElementsHighlight highlighter) {
		this.fullSimpleIDMap = fullSimpleIDMap;
		this.eObjectsWithID = eObjectsWithID;
		this.highlighter=highlighter;
	}
    
    
    private synchronized def highlightModelElements(){
    	var modelElements=getObjectsToHighlight();
    	highlighter.highlightObjects(modelElements);
    	
    }
    private synchronized def List<EObject> getObjectsToHighlight(){
    	return objectsToHighlight;
    }
	public def iterateMap() {
		var it = fullSimpleIDMap.entrySet().iterator();
		while (it.hasNext()) {
			var pair = it.next();
			System.out.println(pair.getKey() + " = " + pair.getValue());
			it.remove(); // avoids a ConcurrentModificationException
		}
	}
	public def InputStream createGeneratedPrologFilesInputStream(Iterable<Quadruple<String,String,String,IProject>> generatedPrologFiles){
		var allFilesString=""
		for (generatedPrologFile : generatedPrologFiles) {
			val content = generatedPrologFile.first
			allFilesString+=content
		}
		var allFilesStream = new ByteArrayInputStream(allFilesString.getBytes(StandardCharsets.UTF_8))
		return allFilesStream;
	} 

	public def String findFullID(String simpleID) {	
		  for (Map.Entry<Object,Integer> entry : fullSimpleIDMap.entrySet()) {
		  	//System.out.println(entry.getKey() + " = " + entry.getValue());
		  	if (entry.getValue().toString().equals(simpleID))
				return entry.getKey().toString();
		  }
		return simpleID;
	}
	public synchronized def EObject findEObjectByFullID(String fullID){
			return eObjectsWithID.get(fullID)
	}

	public synchronized def start(InputStream generatedFilesStream) {
		//var jip = new JIPEngine();
		jip.addEventListener(this);
		jip.addTraceListener(this);
		var urlDefault = new URL("platform:/plugin/edu.kit.kastel.scbs.pcm2prologxsb/default.repository.P");
		var inputStreamDefault = urlDefault.openConnection().getInputStream();
		var totalInputStream=new SequenceInputStream(generatedFilesStream, inputStreamDefault)
		jip.consultStream(totalInputStream, 'jidata');
		inputStreamDefault.close();
		var queryContent = "attacker(Attacker), isInSecureWithRespectTo(Attacker,Service).";
		var query = jip.getTermParser().parseTerm(queryContent);
		synchronized (jip) {
			m_nQueryHandle = jip.openQuery(query);
		}
	}

	override closeNotified(JIPEvent e) {
		synchronized(e.getSource())
        {
            if(m_nQueryHandle == e.getQueryHandle())
            {
                System.out.println("close");
            }
        }
        // notify end
        //notify();
	}

	override endNotified(JIPEvent e) {
		synchronized (e.getSource()) {
			if (m_nQueryHandle == e.getQueryHandle()) {
				System.out.println("end");
				// get the source of the query
				var jip = e.getSource();
				// close query
				jip.closeQuery(m_nQueryHandle);
				highlightModelElements();
				end=true;
			}
		}

		// notify end
		// notify();
	}

	override errorNotified(JIPErrorEvent e) {
		synchronized (e.getSource()) {
			if (m_nQueryHandle == e.getQueryHandle()) {
				System.out.println("Error:");
				System.out.println(e.getError());
				// get the source of the query
				var jip = e.getSource();
				// close query
				jip.closeQuery(m_nQueryHandle);
			}
		}
	}

	override moreNotified(JIPEvent e) {
		synchronized (e.getSource()) {
			if (m_nQueryHandle == e.getQueryHandle()) {
				System.out.println("more");
			}
		}
	}

	override openNotified(JIPEvent e) {
		synchronized (e.getSource()) {
			if (m_nQueryHandle == e.getQueryHandle()) {
				System.out.println("open");
			}
		}
	}

	override solutionNotified(JIPEvent e) {
		synchronized (e.getSource()) {
			if (m_nQueryHandle == e.getQueryHandle()) {
				System.out.println("***********************Solution*****************************:");
				System.out.println(e.getTerm());
				var solution = e.getTerm();
				var vars = solution.getVariables();
				for (JIPVariable sol : vars) {
					if (!sol.isAnonymous()) {
						var idValue=findFullID(sol.toString(e.getSource()))
						System.out.print(sol.getName() + " = " + idValue + " ");
						System.out.println()	
						System.out.println("EObject:")
						var targetEObject=findEObjectByFullID(idValue);
						System.out.println(targetEObject)
						objectsToHighlight.add(targetEObject);
						
						// if(Integer.parseInt(var.toString())>=10)
						// System.out.println("Variable is greater 10"); 
						System.out.println();
					}
				}
				e.getSource().nextSolution(e.getQueryHandle());
			}
		}
	}

	override termNotified(JIPEvent e) {
		synchronized(e.getSource())
        {
            if(m_nQueryHandle == e.getQueryHandle())
            {
               System.out.println("term " + e.getTerm());
            }
        }
	}

	override bindNotified(JIPTraceEvent arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override callNotified(JIPTraceEvent arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override exitNotified(JIPTraceEvent arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override failNotified(JIPTraceEvent arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override foundNotified(JIPTraceEvent arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override redoNotified(JIPTraceEvent arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override startNotified(JIPTraceEvent arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override stopNotified(JIPTraceEvent arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

}
