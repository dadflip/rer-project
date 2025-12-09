// ===============================
// Configuration
// ===============================
const API_BASE = '/api';
let authToken = localStorage.getItem('authToken');
let currentUser = null;

// ===============================
// Utils API
// ===============================
async function apiCall(endpoint, options = {}) {
    const headers = {
        'Content-Type': 'application/json',
        ...(authToken && { 'Authorization': `Bearer ${authToken}` }),
        ...options.headers,
    };

    const response = await fetch(`${API_BASE}${endpoint}`, {
        ...options,
        headers,
    });

    if (response.status === 401) {
        logout();
        return;
    }

    return response.json();
}

// ===============================
// Auth
// ===============================
async function login(username, password) {
    try {
        const data = await apiCall('/token/', {
            method: 'POST',
            body: JSON.stringify({ username, password }),
        });

        authToken = data.access;
        localStorage.setItem('authToken', authToken);
        localStorage.setItem('refreshToken', data.refresh);

        await loadCurrentUser();
        renderDocumentsList();
    } catch (error) {
        alert('Erreur de connexion: ' + error.message);
    }
}

function logout() {
    authToken = null;
    currentUser = null;
    localStorage.removeItem('authToken');
    localStorage.removeItem('refreshToken');
    renderLoginForm();
}

async function loadCurrentUser() {
    currentUser = await apiCall('/users/me/');
    document.getElementById('university-name').textContent =
        currentUser.university?.name || 'N/A';
}

// ===============================
// RENDER: Login
// ===============================
function renderLoginForm() {
    document.getElementById('content').innerHTML = `
        <div class="login-form">
            <h2>Connexion au RER</h2>
            <form id="login-form">
                <input type="text" id="username" placeholder="Nom d'utilisateur" required>
                <input type="password" id="password" placeholder="Mot de passe" required>
                <button type="submit">Se connecter</button>
            </form>
        </div>
    `;

    document.getElementById('login-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        await login(
            document.getElementById('username').value,
            document.getElementById('password').value
        );
    });
}

// ===============================
// RENDER: Documents
// ===============================
async function renderDocumentsList(endpoint = '/documents/') {
    const documents = await apiCall(endpoint);

    document.getElementById('content').innerHTML = `
        <div class="documents-header">
            <h2>Documents disponibles</h2>
            <div class="filters">
                <input type="search" id="search" placeholder="Rechercher...">
                <select id="filter-type">
                    <option value="">Tous les types</option>
                    <option value="ARTICLE">Articles</option>
                    <option value="THESIS">Thèses</option>
                    <option value="COURSE">Cours</option>
                </select>
                <select id="filter-university" id="filter-university"></select>
            </div>
        </div>

        <div class="documents-grid" id="documents-grid">
            ${documents.results.map(doc => `
                <div class="document-card" data-id="${doc.id}">
                    <h3>${doc.title}</h3>
                    <p class="authors">${doc.authors}</p>
                    <div class="meta">
                        <span class="type">${doc.type}</span>
                        <span class="university">${doc.university_name}</span>
                    </div>
                    <div class="actions">
                        <button onclick="viewDocument(${doc.id})">Voir</button>
                        <button onclick="downloadDocument(${doc.id})">Télécharger</button>
                    </div>
                </div>
            `).join('')}
        </div>

        <div class="pagination">
            ${documents.previous ? `<button onclick="renderDocumentsList('${documents.previous.replace(API_BASE, '')}')">⬅️ Précédent</button>` : ''}
            ${documents.next ? `<button onclick="renderDocumentsList('${documents.next.replace(API_BASE, '')}')">Suivant ➡️</button>` : ''}
        </div>
    `;

    await loadUniversityFilter();
}

async function loadUniversityFilter() {
    const universities = await apiCall('/universities/');
    const select = document.getElementById('filter-university');

    select.innerHTML = `
        <option value="">Toutes les universités</option>
        ${universities.results.map(u =>
            `<option value="${u.id}">${u.name}</option>`
        ).join('')}
    `;
}

// ===============================
// Actions documents
// ===============================
async function viewDocument(id) {
    const doc = await apiCall(`/documents/${id}/`);
    await apiCall(`/documents/${id}/log_access/`, {
        method: 'POST',
        body: JSON.stringify({ action: 'VIEW' }),
    });

    alert(`Document: ${doc.title}\n\nAuteurs: ${doc.authors}\n\nRésumé: ${doc.abstract}`);
}

async function downloadDocument(id) {
    await apiCall(`/documents/${id}/log_access/`, {
        method: 'POST',
        body: JSON.stringify({ action: 'DOWNLOAD' }),
    });

    window.open(`${API_BASE}/documents/${id}/download/`, '_blank');
}

// ===============================
// RENDER: Upload document
// ===============================
function renderUploadForm() {
    document.getElementById('content').innerHTML = `
        <h2>Uploader un document</h2>
        <form id="upload-form" enctype="multipart/form-data">
            <input type="text" id="title" placeholder="Titre" required>
            <input type="text" id="authors" placeholder="Auteur(s)" required>
            <select id="type">
                <option value="ARTICLE">Article</option>
                <option value="THESIS">Thèse</option>
                <option value="COURSE">Cours</option>
            </select>
            <input type="file" id="file" required>
            <button type="submit">Uploader</button>
        </form>
    `;

    document.getElementById('upload-form').addEventListener('submit', uploadDocument);
}

async function uploadDocument(e) {
    e.preventDefault();

    const formData = new FormData();
    formData.append('title', document.getElementById('title').value);
    formData.append('authors', document.getElementById('authors').value);
    formData.append('type', document.getElementById('type').value);
    formData.append('file', document.getElementById('file').files[0]);

    await fetch(`${API_BASE}/documents/upload/`, {
        method: 'POST',
        headers: {
            ...(authToken && { 'Authorization': `Bearer ${authToken}` }),
        },
        body: formData,
    });

    alert('Document uploadé avec succès !');
    renderDocumentsList();
}

// ===============================
// RENDER: Stats
// ===============================
async function renderStats() {
    const stats = await apiCall('/documents/stats/');

    document.getElementById('content').innerHTML = `
        <h2>Statistiques</h2>
        <ul>
            <li>Total documents: ${stats.total}</li>
            <li>Téléchargements: ${stats.downloads}</li>
            <li>Vues: ${stats.views}</li>
        </ul>
    `;
}

// ===============================
// RENDER: Profil utilisateur
// ===============================
async function renderProfile() {
    document.getElementById('content').innerHTML = `
        <h2>Profil utilisateur</h2>
        <p><strong>Nom:</strong> ${currentUser.username}</p>
        <p><strong>Email:</strong> ${currentUser.email}</p>
        <p><strong>Université:</strong> ${currentUser.university?.name || 'N/A'}</p>
    `;
}

// ===============================
// Navigation
// ===============================
document.getElementById('btn-logout')?.addEventListener('click', logout);

document.getElementById('nav-documents')?.addEventListener('click', (e) => {
    e.preventDefault();
    renderDocumentsList();
});

document.getElementById('nav-upload')?.addEventListener('click', (e) => {
    e.preventDefault();
    renderUploadForm();
});

document.getElementById('nav-stats')?.addEventListener('click', (e) => {
    e.preventDefault();
    renderStats();
});

document.getElementById('nav-profile')?.addEventListener('click', (e) => {
    e.preventDefault();
    renderProfile();
});

// ===============================
// Initialisation
// ===============================
if (authToken) {
    loadCurrentUser().then(() => renderDocumentsList());
} else {
    renderLoginForm();
}
