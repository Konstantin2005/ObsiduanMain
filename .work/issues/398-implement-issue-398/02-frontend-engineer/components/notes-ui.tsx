// Сервис пользовательского интерфейса

import React from 'react';
import { useState, useEffect } from 'react';
import axios from 'axios';
import styled from 'styled-components';

export interface Note {
    id: string;
    title: string;
    content: string;
    syntax: string;
    tags: string[];
    labels: string[];
    path: string;
    owner: string;
    group: string;
    created_at: string;
    updated_at: string;
    status: 'draft' | 'published' | 'archived';
    ttl?: number;
}

export interface NotesUIProps {
    apiBaseUrl: string;
}

export const NotesUI: React.FC<NotesUIProps> = ({ apiBaseUrl }) => {
    const [notes, setNotes] = useState<Note[]>([]);
    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string>('');
    const [searchQuery, setSearchQuery] = useState<string>('');
    const [selectedNote, setSelectedNote] = useState<Note | null>(null);

    useEffect(() => {
        loadNotes();
    }, []);

    const loadNotes = async () => {
        try {
            setLoading(true);
            const response = await axios.get(`${apiBaseUrl}/api/notes`);
            setNotes(response.data.data);
        } catch (err) {
            setError('Failed to load notes');
        } finally {
            setLoading(false);
        }
    };

    const createNote = async (noteData: Partial<Note>) => {
        try {
            const response = await axios.post(`${apiBaseUrl}/api/notes`, noteData);
            setNotes([...notes, response.data]);
        } catch (err) {
            setError('Failed to create note');
        }
    };

    const updateNote = async (id: string, updates: Partial<Note>) => {
        try {
            const response = await axios.put(`${apiBaseUrl}/api/notes/${id}`, updates);
            setNotes(notes.map(note => note.id === id ? response.data : note));
            if (selectedNote?.id === id) {
                setSelectedNote(response.data);
            }
        } catch (err) {
            setError('Failed to update note');
        }
    };

    const deleteNote = async (id: string) => {
        try {
            await axios.delete(`${apiBaseUrl}/api/notes/${id}`);
            setNotes(notes.filter(note => note.id !== id));
            if (selectedNote?.id === id) {
                setSelectedNote(null);
            }
        } catch (err) {
            setError('Failed to delete note');
        }
    };

    const exportNote = async (id: string, format: string) => {
        try {
            const response = await axios.post(`${apiBaseUrl}/api/notes/${id}/export`, { format }, { responseType: 'blob' });
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `note-${id}.${format}`);
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (err) {
            setError('Failed to export note');
        }
    };

    const filteredNotes = notes.filter(note =>
        note.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        note.content.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return (
        <Container>
            <Header>
                <h1>Notes API</h1>
                <SearchBar
                    type="text"
                    placeholder="Search notes..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                />
            </Header>

            {error && <ErrorMessage>{error}</ErrorMessage>}

            <MainContent>
                <NotesList>
                    <h2>Notes</h2>
                    {loading ? (
                        <Loading>Loading...</Loading>
                    ) : (
                        <NoteGrid>
                            {filteredNotes.map(note => (
                                <NoteCard
                                    key={note.id}
                                    onClick={() => setSelectedNote(note)}
                                    isSelected={selectedNote?.id === note.id}
                                >
                                    <NoteTitle>{note.title}</NoteTitle>
                                    <NoteMeta>Created: {new Date(note.created_at).toLocaleDateString()}</NoteMeta>
                                    <NoteMeta>Status: {note.status}</NoteMeta>
                                    <NoteActions>
                                        <ActionButton onClick={(e) => { e.stopPropagation(); createNote({ title: `Copy of ${note.title}`, content: note.content, syntax: note.syntax }); } }>
                                            Duplicate
                                        </ActionButton>
                                        <ActionButton onClick={(e) => { e.stopPropagation(); exportNote(note.id, 'markdown'); } }>
                                            Export
                                        </ActionButton>
                                        <DeleteButton onClick={(e) => { e.stopPropagation(); deleteNote(note.id); } }>
                                            Delete
                                        </DeleteButton>
                                    </NoteActions>
                                </NoteCard>
                            ))}
                        </NoteGrid>
                    )}
                </NotesList>

                <NoteDetail>
                    <h2>Note Details</h2>
                    {selectedNote ? (
                        <NoteForm note={selectedNote} onUpdate={updateNote} />
                    ) : (
                        <EmptyState>Select a note to view details</EmptyState>
                    )}
                </NoteDetail>
            </MainContent>

            <CreateNoteForm onCreate={createNote} />
        </Container>
    );
};

// Styled components (simulated)
const Container = styled.div`
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
    font-family: Arial, sans-serif;
`;

const Header = styled.div`
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 30px;
    padding: 20px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border-radius: 10px;
`;

const SearchBar = styled.input`
    padding: 10px 15px;
    border: none;
    border-radius: 5px;
    font-size: 16px;
    width: 300px;
    &:focus {
        outline: none;
        box-shadow: 0 0 10px rgba(0,0,0,0.2);
    }
`;

const ErrorMessage = styled.div`
    background: #ffebee;
    color: #c62828;
    padding: 15px;
    border-radius: 5px;
    margin-bottom: 20px;
    border: 1px solid #ffcdd2;
`;

const MainContent = styled.div`
    display: grid;
    grid-template-columns: 1fr 2fr;
    gap: 30px;
`;

const NotesList = styled.div`
    background: white;
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
`;

const NoteGrid = styled.div`
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 20px;
    margin-top: 20px;
`;

const NoteCard = styled.div`
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    cursor: pointer;
    transition: all 0.3s ease;
    border: 2px solid ${props => props.isSelected ? '#667eea' : 'transparent'};
    &:hover {
        transform: translateY(-5px);
        box-shadow: 0 5px 15px rgba(0,0,0,0.2);
    }
`;

const NoteTitle = styled.h3`
    margin: 0 0 10px 0;
    color: #333;
    font-size: 18px;
`;

const NoteMeta = styled.p`
    margin: 5px 0;
    color: #666;
    font-size: 14px;
`;

const NoteActions = styled.div`
    display: flex;
    gap: 10px;
    margin-top: 15px;
`;

const ActionButton = styled.button`
    padding: 5px 10px;
    border: none;
    border-radius: 4px;
    background: #667eea;
    color: white;
    cursor: pointer;
    font-size: 12px;
    &:hover {
        background: #5a67d8;
    }
`;

const DeleteButton = styled(ActionButton)`
    background: #f44336;
    &:hover {
        background: #d32f2f;
    }
`;

const Loading = styled.div`
    text-align: center;
    padding: 40px;
    color: #666;
`;

const EmptyState = styled.div`
    text-align: center;
    padding: 60px;
    color: #999;
    font-style: italic;
`;

const NoteDetail = styled.div`
    background: white;
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
`;

const NoteForm = styled.div`
    /* Form styles would be here */
`;

const CreateNoteForm = styled.div`
    margin-top: 30px;
    background: white;
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
`;

export default NotesUI;