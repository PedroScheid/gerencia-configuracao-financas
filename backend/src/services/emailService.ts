import nodemailer from "nodemailer";
import { Resend } from "resend";

export interface LancamentoEmailData {
  id: number;
  descricao: string;
  data_lancamento: string;
  valor: number;
  tipo_lancamento: string;
  situacao: string;
}

export type EmailAction = "created" | "updated";

/** Abstraction – implement this interface to swap email providers */
export interface IEmailService {
  sendLancamentoNotification(
    lancamento: LancamentoEmailData,
    action: EmailAction,
    emailTo?: string,
  ): Promise<void>;
}

function buildEmailHtml(
  lancamento: LancamentoEmailData,
  action: EmailAction,
): string {
  const tipo = lancamento.tipo_lancamento === "RECEITA" ? "Receita" : "Despesa";
  const actionLabel = action === "created" ? "criado" : "atualizado";
  const valorFormatado = lancamento.valor.toFixed(2).replace(".", ",");

  return `
    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
      <h2 style="color: #1a56db;">Lançamento ${actionLabel}</h2>
      <table style="width:100%; border-collapse: collapse;">
        <tr>
          <td style="padding: 6px; font-weight: bold;">Tipo:</td>
          <td style="padding: 6px;">${tipo}</td>
        </tr>
        <tr style="background:#f9fafb;">
          <td style="padding: 6px; font-weight: bold;">Valor:</td>
          <td style="padding: 6px;">R$ ${valorFormatado}</td>
        </tr>
        <tr>
          <td style="padding: 6px; font-weight: bold;">Data:</td>
          <td style="padding: 6px;">${lancamento.data_lancamento}</td>
        </tr>
        <tr style="background:#f9fafb;">
          <td style="padding: 6px; font-weight: bold;">Situação:</td>
          <td style="padding: 6px;">${lancamento.situacao}</td>
        </tr>
        ${
          lancamento.descricao
            ? `<tr>
                 <td style="padding: 6px; font-weight: bold;">Descrição:</td>
                 <td style="padding: 6px;">${lancamento.descricao}</td>
               </tr>`
            : ""
        }
      </table>
    </div>
  `;
}

export class NodemailerEmailService implements IEmailService {
  async sendLancamentoNotification(
    lancamento: LancamentoEmailData,
    action: EmailAction,
    emailTo?: string,
  ): Promise<void> {
    const smtpHost = process.env.SMTP_HOST;
    const smtpPort = Number(process.env.SMTP_PORT) || 587;
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;
    const emailTo_ = emailTo ?? process.env.NOTIFICATION_EMAIL;

    // Log das variáveis de ambiente lidas
    console.log("[EmailService] SMTP config:", {
      SMTP_HOST: smtpHost,
      SMTP_PORT: smtpPort,
      SMTP_USER: smtpUser,
      SMTP_PASS: smtpPass ? "(set)" : undefined,
      NOTIFICATION_EMAIL: emailTo,
      SMTP_SECURE: process.env.SMTP_SECURE,
    });

    if (!smtpHost || !smtpUser || !smtpPass || !emailTo_) {
      console.warn(
        "[EmailService] Notification skipped: SMTP configuration missing. " +
          "Set SMTP_HOST, SMTP_USER, SMTP_PASS and NOTIFICATION_EMAIL.",
      );
      return;
    }

    const isSecure = process.env.SMTP_SECURE === "true";

    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: isSecure, // true = porta 465 (SSL), false = porta 587/2525 (STARTTLS)
      requireTLS: !isSecure, // força STARTTLS nas portas 587, 2525 e 25
      auth: { user: smtpUser, pass: smtpPass },
    });

    const tipo =
      lancamento.tipo_lancamento === "RECEITA" ? "Receita" : "Despesa";
    const actionLabel = action === "created" ? "criado" : "atualizado";
    const subject = `Lançamento ${actionLabel}: ${tipo} – R$ ${lancamento.valor.toFixed(2)}`;

    // Log do envio
    console.log("[EmailService] Enviando e-mail:", {
      from: smtpUser,
      to: emailTo_,
      subject,
      action,
      tipo: lancamento.tipo_lancamento,
      valor: lancamento.valor,
      data: lancamento.data_lancamento,
      situacao: lancamento.situacao,
      descricao: lancamento.descricao,
    });

    try {
      await transporter.sendMail({
        from: smtpUser,
        to: emailTo_,
        subject,
        html: buildEmailHtml(lancamento, action),
      });
      console.log("[EmailService] E-mail enviado com sucesso!");
    } catch (err) {
      console.error("[EmailService] Falha ao enviar e-mail:", err);
      throw err;
    }
  }
}

export { buildEmailHtml };

// ---------------------------------------------------------------------------
// ResendEmailService – uses the Resend HTTP API (never blocked by firewalls)
// Configure via: RESEND_API_KEY and NOTIFICATION_EMAIL in .env
// ---------------------------------------------------------------------------
export class ResendEmailService implements IEmailService {
  async sendLancamentoNotification(
    lancamento: LancamentoEmailData,
    action: EmailAction,
    emailTo?: string,
  ): Promise<void> {
    const apiKey = process.env.RESEND_API_KEY;
    const emailTo_ = emailTo ?? process.env.NOTIFICATION_EMAIL;

    if (!apiKey || !emailTo_) {
      console.warn(
        "[ResendEmailService] Notificação ignorada: defina RESEND_API_KEY e NOTIFICATION_EMAIL no .env",
      );
      return;
    }

    const resend = new Resend(apiKey);

    const tipo =
      lancamento.tipo_lancamento === "RECEITA" ? "Receita" : "Despesa";
    const actionLabel = action === "created" ? "criado" : "atualizado";
    const subject = `Lançamento ${actionLabel}: ${tipo} – R$ ${lancamento.valor.toFixed(2)}`;

    console.log("[ResendEmailService] Enviando e-mail:", {
      to: emailTo_,
      subject,
      action,
      tipo: lancamento.tipo_lancamento,
      valor: lancamento.valor,
      data: lancamento.data_lancamento,
    });

    const { error } = await resend.emails.send({
      from: "Finanças <onboarding@resend.dev>",
      to: emailTo_,
      subject,
      html: buildEmailHtml(lancamento, action),
    });

    if (error) {
      console.error("[ResendEmailService] Falha ao enviar e-mail:", error);
      throw new Error(`Resend error: ${error.message}`);
    }

    console.log("[ResendEmailService] E-mail enviado com sucesso!");
  }
}
