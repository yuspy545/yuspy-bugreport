let isOpen = false;
let isBugListOpen = false;
let resourceName = 'bugreport'; 
let currentFilter = 'all';
let bugs = [];

console.log('[yuspy-bugreport UI] loaded');
let mouseSeen = false;
window.addEventListener('mousemove', function () {
    mouseSeen = true;
});

function ensureUIFocus(selector) {
    let attempts = 0;
    const maxAttempts = 12;
    const tryFocus = () => {
        attempts++;
        try {
            document.body.style.pointerEvents = 'auto';
            const el = selector ? document.querySelector(selector) : null;
            if (el && typeof el.focus === 'function') {
                el.focus();
            } else if (selector == null) {
                window.focus && window.focus();
            }
        } catch (e) {
           
        }
        if (attempts < maxAttempts) {
            setTimeout(tryFocus, 50);
        }
    };
    tryFocus();
}

window.addEventListener('message', (event) => {
    const data = event.data;
    console.log('[yuspy-bugreport UI] message received:', data && data.action, data);
    if (data && data.action === 'bugListReceived') {
        try {
            const count = Array.isArray(data.bugs) ? data.bugs.length : (data.bugs && typeof data.bugs === 'object' ? Object.keys(data.bugs).length : 0);
            console.log(`[yuspy-bugreport UI] bugListReceived count: ${count}`, data.bugs && data.bugs.slice ? data.bugs.slice(0,5) : data.bugs);
        } catch (e) {
            console.error('Error logging bugListReceived payload', e, data.bugs);
        }
    }
    
    if (data.action === 'open') {
        if (data.resourceName) {
            resourceName = data.resourceName;
        }
        openBugReport();
        ensureUIFocus('#bugTitle');
    } else if (data.action === 'close') {
        closeBugReport();
    } else if (data.action === 'openBugList') {
        if (data.resourceName) {
            resourceName = data.resourceName;
        }
        openBugList();
        ensureUIFocus('#bugListContainer');
    } else if (data.action === 'closeBugList') {
        closeBugList();
    } else if (data.action === 'bugListReceived') {
        bugs = data.bugs || [];
        displayBugList();
    } else if (data.action === 'statusUpdated') {
        if (data.success) {
            const bug = bugs.find(b => b.id === data.bugId);
            if (bug) bug.status = data.status;
            displayBugList();
        } else {
            console.error('Status update failed:', data.error);
            alert('Failed to update bug status: ' + (data.error || 'Unknown'));
        }
    } else if (data.action === 'bugDeleted') {
        if (data.success) {
            bugs = bugs.filter(b => b.id !== data.bugId);
            displayBugList();
        } else {
            console.error('Delete failed:', data.error);
            alert('Error deleting bug: ' + (data.error || 'Unknown'));
        }
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && isOpen) {
        closeBugReportRequest();
    }
});

function openBugReport() {
    const container = document.getElementById('bugReportContainer');
    container.classList.remove('hidden');
    isOpen = true;
    document.body.style.pointerEvents = 'auto';
    mouseSeen = false;
    let attempts = 0;
    const poll = setInterval(() => {
        attempts++;
        document.body.style.pointerEvents = 'auto';
        try { document.querySelector('#bugTitle')?.focus(); } catch(e){}
        if (mouseSeen || attempts > 12) clearInterval(poll);
    }, 100);
}

function closeBugReport() {
    const container = document.getElementById('bugReportContainer');
    container.classList.add('hidden');
    isOpen = false;
    document.body.style.pointerEvents = 'none';
    document.getElementById('bugReportForm').reset();
}

function closeBugReportRequest() {
    closeBugReport();
    fetch(`https://${resourceName}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(err => console.error('Error requesting close:', err));
}

document.getElementById('bugReportForm').addEventListener('submit', (event) => {
    event.preventDefault();
    
    const formData = {
        title: document.getElementById('bugTitle').value,
        category: document.getElementById('bugCategory').value,
        description: document.getElementById('bugDescription').value,
        steps: document.getElementById('bugSteps').value,
        priority: document.getElementById('bugPriority').value,
        timestamp: new Date().toISOString()
    };
    
    fetch(`https://${resourceName}/submitBug`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
    }).then(() => {
        closeBugReport();
    }).catch((error) => {
        console.error('Error submitting bug report:', error);
    });
});

document.getElementById('closeBtn').addEventListener('click', closeBugReportRequest);
document.getElementById('cancelBtn').addEventListener('click', closeBugReportRequest);
document.getElementById('closeBugListBtn').addEventListener('click', closeBugListRequest);


function openBugList() {
    const container = document.getElementById('bugListContainer');
    container.classList.remove('hidden');
    isBugListOpen = true;
    document.body.style.pointerEvents = 'auto';
    mouseSeen = false;
    let attempts = 0;
    const poll = setInterval(() => {
        attempts++;
        document.body.style.pointerEvents = 'auto';
        try { document.querySelector('#bugListContainer')?.focus(); } catch(e){}
        if (mouseSeen || attempts > 12) clearInterval(poll);
    }, 100);
    fetchBugList();
}

function closeBugList() {
    const container = document.getElementById('bugListContainer');
    container.classList.add('hidden');
    isBugListOpen = false;
    document.body.style.pointerEvents = 'none';
}

function closeBugListRequest() {
    closeBugList();
    fetch(`https://${resourceName}/closeBugList`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(err => console.error('Error requesting closeBugList:', err));
}

function fetchBugList() {
    const bugListItems = document.getElementById('bugListItems');
    bugListItems.innerHTML = '<div class="loading-spinner"><div class="spinner"></div><p>Loading...</p></div>';
    
    fetch(`https://${resourceName}/getBugList`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
    .then(() => {
        setTimeout(() => {
                if (!bugs || bugs.length === 0) {
                bugListItems.innerHTML = '<div class="empty-message">No bugs found.</div>';
            }
        }, 3000);
    })
    .catch(error => {
        console.error('Error fetching bug list:', error);
        bugListItems.innerHTML = '<div class="error-message">An error occurred while loading the bug list.</div>';
    });
}

function displayBugList() {
    const bugListItems = document.getElementById('bugListItems');
    
    let filteredBugs = bugs;
    if (currentFilter !== 'all') {
        filteredBugs = bugs.filter(bug => bug.status === currentFilter);
    }
    
    if (filteredBugs.length === 0) {
        bugListItems.innerHTML = '<div class="empty-message">No bugs found.</div>';
        return;
    }
    
    bugListItems.innerHTML = filteredBugs.map(bug => {
        const statusClass = `status-${bug.status}`;
        const statusText = {
            'pending': 'Pending',
            'checked': 'Checked',
            'fixed': 'Fixed'
        }[bug.status] || bug.status;
        
        const priorityClass = `priority-${bug.priority}`;
        const priorityText = bug.priority.charAt(0).toUpperCase() + bug.priority.slice(1);
        
        const categoryText = {
            'gameplay': 'Gameplay',
            'ui': 'UI',
            'performance': 'Performance',
            'item': 'Item',
            'vehicle': 'Vehicle',
            'other': 'Other'
        }[bug.category] || bug.category;
        
        const date = new Date(bug.created_at);
        const formattedDate = date.toLocaleDateString('tr-TR', { 
            day: '2-digit', 
            month: '2-digit', 
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        
        const deleteButton = bug.status === 'fixed' 
            ? `<button class="btn-delete" onclick="deleteBug(${bug.id})" title="Sil">
                <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M3 6H5H21M8 6V4C8 3.46957 8.21071 2.96086 8.58579 2.58579C8.96086 2.21071 9.46957 2 10 2H14C14.5304 2 15.0391 2.21071 15.4142 2.58579C15.7893 2.96086 16 3.46957 16 4V6M19 6V20C19 20.5304 18.7893 21.0391 18.4142 21.4142C18.0391 21.7893 17.5304 22 17 22H7C6.46957 22 5.96086 21.7893 5.58579 21.4142C5.21071 21.0391 5 20.5304 5 20V6H19Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
            </button>`
            : '';
        
        return `
            <div class="bug-item" data-id="${bug.id}">
                <div class="bug-item-header">
                    <div class="bug-item-title-section">
                        <h3 class="bug-item-title">#${bug.id} - ${escapeHtml(bug.title)}</h3>
                        <div class="bug-item-meta">
                            <span class="bug-category">${escapeHtml(categoryText)}</span>
                            <span class="bug-priority ${priorityClass}">${escapeHtml(priorityText)}</span>
                            <span class="bug-date">${formattedDate}</span>
                        </div>
                    </div>
                    <div class="bug-item-actions">
                        <span class="bug-status ${statusClass}">${statusText}</span>
                        ${deleteButton}
                    </div>
                </div>
                <div class="bug-item-body">
                    <p class="bug-description">${escapeHtml(bug.description)}</p>
                    ${bug.steps ? `<div class="bug-steps"><strong>Adımlar:</strong> ${escapeHtml(bug.steps)}</div>` : ''}
                    <div class="bug-player-info">
                        <span><strong>Oyuncu:</strong> ${escapeHtml(bug.player_name || 'Bilinmiyor')}</span>
                    </div>
                </div>
                <div class="bug-item-footer">
                    <select class="status-select" onchange="updateBugStatus(${bug.id}, this.value)">
                        <option value="pending" ${bug.status === 'pending' ? 'selected' : ''}>Pending</option>
                        <option value="checked" ${bug.status === 'checked' ? 'selected' : ''}>Checked</option>
                        <option value="fixed" ${bug.status === 'fixed' ? 'selected' : ''}>Fixed</option>
                    </select>
                </div>
            </div>
        `;
    }).join('');
}

function updateBugStatus(bugId, newStatus) {
    fetch(`https://${resourceName}/updateBugStatus`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ bugId: bugId, status: newStatus })
    }).catch(error => {
        console.error('Error updating bug status:', error);
        alert('An error occurred while updating the bug status.');
    });
}

function deleteBug(bugId) {
    fetch(`https://${resourceName}/deleteBug`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ bugId: bugId })
    })
    .then(response => {
        if (!response.ok) {
            console.error('Delete request failed with status', response.status);
            alert('An error occurred while deleting the bug.');
        }
    })
    .catch(error => {
        
    });
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

document.querySelectorAll('.filter-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        currentFilter = this.dataset.status;
        displayBugList();
    });
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        if (isOpen) {
            closeBugReportRequest();
        }
        if (isBugListOpen) {
            closeBugListRequest();
        }
    }
});