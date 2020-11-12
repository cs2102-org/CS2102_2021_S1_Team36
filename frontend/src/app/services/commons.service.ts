import { HttpHeaders } from '@angular/common/http';

function getHttpOptionsWithAuth() {
    const accessToken = localStorage.getItem('accessToken');
    if (accessToken == null) {
        return httpOptions;
    }
    const headerWithToken = httpOptions['headers'].append('Authorization', `Bearer ${accessToken}`);
    const httpOptionsWithAuth = {
        headers: headerWithToken,
    }
    return httpOptionsWithAuth;
}

export const baseurl = 'https://rocky-anchorage-72998.herokuapp.com';
export const httpOptions = {
    headers: new HttpHeaders({ 'Content-Type': 'application/json' }),
};
export { getHttpOptionsWithAuth as getHttpOptionsWithAuth }