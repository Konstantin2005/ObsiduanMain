import React, { useState, useEffect, useCallback } from 'react';
import { PeopleNode, PeopleEdge } from '../../types/people-links';

interface PeopleLinkNodeProps {
  node: PeopleNode;
}

export const PeopleLinkNode: React.FC<PeopleLinkNodeProps> = ({ node }) => {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <div className="people-link-node">
      <div 
        className="node-header"
        onClick={() => setIsExpanded(!isExpanded)}
      >
        <span className="node-name">{node.name}</span>
        <span className="node-aliases">
          ({node.aliases.join(', ')})
        </span>
        <button className="expand-btn">
          {isExpanded ? '▼' : '▶'}
        </button>
      </div>
      
      {isExpanded && (
        <div className="node-details">
          <div className="note-count">
            Notes: {node.noteIds.length}
          </div>
          <div className="note-list">
            <strong>References:</strong>
            <ul>
              {node.noteIds.map(noteId => (
                <li key={noteId}>{noteId}</li>
              ))}
            </ul>
          </div>
        </div>
      )}
    </div>
  );
};
